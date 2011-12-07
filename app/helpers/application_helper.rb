module ApplicationHelper
  
  def title 
    base_title = "Advanced Study Room"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end
  
  def sub_title
    "#{@title}"
  end
      
  def rank_convert(rank)
    if not rank[0]
      return -31
    end
    rank = rank[0]
    if rank[-1,1] == "d"
      newrank = rank.scan(/[1-9]/)[0]
      newrank = Integer(newrank)
      rank_boolean = true
      return newrank
    elsif rank[-1,1] == "k"
      newrank = rank.scan(/[1-9]/)[0]
      newrank = Integer(newrank) * -1 + 1
      rank_boolean = true
      return newrank
    elsif (rank == "?") or (rank == "-")
      newrank = -31
      rank_boolean = false
    else
      puts "I DID NOT KNOW WHAT TO DO."
    end
  end
    
  def scrape
    
    kgsnames = User.select("kgs_names")
    
    for x in kgsnames
      if not x.kgs_names
        next
      end
      match_scraper(x.kgs_names)
    end
  end

  def processRow(row)
    # This next line gets the 1st <a> tag in the first <td> tag (which is our sgf link), or nil if it's a private game.
    
    url = row.at('a')[:href]

    if row.xpath('td[@colspan="2"]')
      column[1] = row.xpath('td[@colspan="2"]').map do |x|
      puts x.css('a')
    end
    
    columns = row.css('td')
    
    # <td colspan="2">
    # <a href="gameArchives.jsp?user=niark">niark [-]</a>
    #  (<a href="gameArchives.jsp?user=ciaso">ciaso [-]</a> vs. <a href="gameArchives.jsp?user=niark">niark [-]</a>)
    #  </td>
    
    public_game = columns[0].content
    puts columns[1]
    
    # Calculate white player name and rank
    white_player_name = columns[1].content.scan(/^\w+/)[0]
    white_player_rank = columns[1].content.scan(/\?|-|[1-9]?[1-9][kdp]/)
    white_player_rank = rank_convert(white_player_rank)
    
    # Calculate black player name and rank
    black_player_name = columns[2].content.scan(/^\w+/)[0]
    black_player_rank = columns[2].content.scan(/\?|-|[1-9]?[1-9][kdp]/)
    black_player_rank = rank_convert(black_player_rank)
    
    # Parse board size
    board_size_and_handicap = columns[3].content
    boardArray = columns[3].content.scan(/[0-9]+/)
    board_size = Integer(boardArray[0])
  
    if boardArray.length() == 3
      handi = Integer(boardArray[2])
    else
      handi = Integer(0)
    end
    
    # Calculate UNIX time
    date = columns[4].content
    puts date
    unixtime = DateTime.strptime(date, "%m/%d/%Y %I:%M %p").utc.to_time.to_i * -1
    
    game_type = columns[5].content
    
    # Parse game results
    result = columns[6].content
    resArray = result.split('+')
    score = 0
    if resArray[0] == ("W")
      result_boolean = true
    else
      result_boolean = false
    end
    if resArray[1] == "Res." 
      score = -1.0
    elsif resArray[1] == "Forf." 
      score = -2.0
    elsif resArray[1] == "Time" 
      score = -3.0
    elsif resArray[1] == nil
      score = 0
    else 
      score = Float(resArray[1])
    end 
  
    return {"url" => url, "white_player_name" => white_player_name, "white_player_rank" => white_player_rank, "black_player_name" => black_player_name, "black_player_rank" => black_player_rank, "result_boolean" => result_boolean, "score" => score, "board_size" => board_size, "handi" => handi, "unixtime" => unixtime, "game_type" => game_type, "public_game" => public_game, "result" =>result}
  end

  def sgfParser(url)
    # SGF Parser
    
    require 'net/http'
    require 'open-uri'
    require 'sgf'
    sgf_raw = open(url).read
    parser = SGF::Parser.new 
    tree = parser.parse sgf_raw
    
    game_info = tree.root.children[0].properties
    puts game_info.inspect
    valid_sgf = true
    invalid_reason = []
    
    # Confirm 'ASR League' is mentioned within first 30 moves
    game = tree.root
    for i in 0..30
      comment = game.properties["C"]
      if not comment
        break
        invalid_reason << "did not contain any comments"
        valid_sgf = false
      end
      if comment.scan(/ASR League/i)
        valid_sgf = true
      else
        invalid_reason << "did not contain tag line"
        valid_sgf = false
      end
      game = game.children[0]
    end
    
    # Check that over time is at least 5x30 byo-yomi
    over_time = game_info["OT"]
    if over_time == nil
      invalid_reason << "over_time was nil"
      valid_sgf = false
    end
    
    # Restrict overtime settings
    over_time = over_time.split(' ')
    byo_yomi_periods = over_time[0].split('x')[0].to_i # Parse SGF overtime periods
    byo_yomi_seconds = over_time[0].split('x')[1].to_i # Parse SGF overtime seconds

    if (byo_yomi_periods < 5) and (byo_yomi_seconds < 30)
      invalid_reason << "incorrect byo-yomi: #{byo_yomi_periods}, #{byo_yomi_seconds}"
      valid_sgf = false
    end
    
    # Check main time is not less than 1500
    main_time = game_info["TM"].to_i
    
    if main_time < 1500
      invalid_reason << "incorrect main time: #{main_time}"
      valid_sgf = false
    end        
    
    # Check ruleset is Japanese
    ruleset = game_info["RU"]
    
    if ruleset != "Japanese"
      invalid_reason << "incorrect ruleset: #{ruleset}"
      valid_sgf = false
    end
    
    # Omit games with the Canadian ruleset
    if over_time["Canadian"]
      ruleset = "Canadian"
    end
    
    # Check komi is 6.5 or 0.5
    komi = game_info["KM"][1..-2].to_f
    
    unless komi == 6.5
      invalid_reason << "incorrect komi: #{komi}"
      valid_sgf = false
    end

    
    
    return [byo_yomi_periods, byo_yomi_seconds, main_time, ruleset, komi, valid_sgf, invalid_reason]
  end

  def match_scraper(kgs_name)
    
    require 'open-uri'
    require 'time'
      
    doc = Nokogiri::HTML(open("http://www.gokgs.com/gameArchives.jsp?user=#{kgs_name}"))
    doc = doc.xpath('//table[1]')
    doc = doc.css('tr:not(:first)')
    
    games = []
    
    doc.each do |row|
      games << processRow(row)
    end
    
    # Various filters
    invalid_reason = []
    for row in games
      parsedurl = row["url"]
      if row["public_game"] == "No"
        # puts "game was private"
        next
      elsif User.where("url = {parsedurl}")
        # puts "Duplicate url"
        next
      elsif row["board_size"] != 19
        invalid_reason << "incorrect board size"
        valid_game = false
      elsif row["game_type"] == "Rengo"
        invalid_reason << "was a rengo game"
        valid_game = false
      elsif row["game_type"] == "Teaching"
        invalid_reason << "was a teaching game"
        valid_game = false
      elsif row["handi"] != 0
        invalid_reason << "incorrect handicap"
        valid_game = false
      else
        sgf = sgfParser(row["url"])
        
        for x in sgf[6]
          invalid_reason << x
        end
        
        if sgf[3] == "Canadian"
          # puts "Canadian ruleset not valid"
          next
        end
        
        if sgf[5] == false
          valid_game = false
        end

        # Submit game to DB
        rowadd = Match.new(:url => row["url"], :white_player_name => row["white_player_name"],
                                               :white_player_rank => row["white_player_rank"],
                                               :black_player_name => row["black_player_name"], 
                                               :black_player_rank => row["black_player_rank"], 
                                               :result_boolean => row["result_boolean"], 
                                               :score => row["score"], 
                                               :board_size => row["board_size"], 
                                               :handi => row["handi"], 
                                               :unixtime => row["unixtime"], 
                                               :game_type => row["game_type"], 
                                               :ruleset => sgf[3], 
                                               :komi => sgf[4],
                                               :result => row["result"],
                                               :main_time => sgf[2],
                                               :byo_yomi_periods => sgf[0], 
                                               :byo_yomi_seconds => sgf[1],
                                               :invalid_reason => invalid_reason.to_s,
                                               :valid_game => valid_game)
        rowadd.save
      end # End if .. else statement
    end # End for loop
   
   end
  
end
