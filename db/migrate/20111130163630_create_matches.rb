class CreateMatches < ActiveRecord::Migration
  def change
    create_table :matches do |t|
      t.string :url
      t.string :white_player_name
      t.integer :white_player_rank
      t.string :black_player_name
      t.integer :black_player_rank
      t.boolean :result_boolean
      t.float :score
      t.integer :board_size
      t.integer :handi
      t.integer :unixtime
      t.string :game_type
      t.float :komi
      t.string :result
      t.boolean :valid_game

      t.timestamps
    end
  end
end
