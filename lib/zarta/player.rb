# The catch-all module for Zarta
module Zarta
  # The player character
  class Player
    # The player's name
    attr_accessor :name

    # The player's health in an array
    # [current health / max health]
    attr_accessor :health

    # The player's current experience level
    attr_accessor :level

    # The player's accumulated experience points
    attr_accessor :xp

    # The player's current weapon
    attr_accessor :weapon

    def initialize(dungeon)
      @name    = 'Testy McTestface'
      @health  = [100, 100]
      @level   = 1
      @xp      = 0
      @weapon  = []
      @dungeon = dungeon
      @prompt  = TTY::Prompt.new
      @pastel  = Pastel.new
    end

    def starting_weapon
      @weapon = Zarta::Weapon.new(@dungeon)
    end

    def handle_weapon
      # I'm not making weapon  an instance variable as it may be
      # different every time this method is called
      weapon = @dungeon.room.weapon.name
      weapon = @pastel.cyan.bold(weapon)
      puts "You see a #{weapon} just laying around."

      # Repeat until they pick it up or leave it
      loop do
        weapon = @dungeon.room.weapon
        weapon_choice = weapon_prompt

        if weapon_choice == 'Pick it up'
          break if pickup_weapon(weapon)
        end

        weapon.inspect_weapon if weapon_choice == 'Look at it'

        return if weapon_choice == 'Leave it' && @prompt.yes?('Are you sure?')
      end
    end

    def weapon_prompt
      @prompt.select('What do you want to do?') do |menu|
        menu.choice 'Pick it up'
        menu.choice 'Look at it'
        menu.choice 'Leave it'
      end
    end

    def pickup_weapon(weapon)
      puts 'Your current weapon will be replaced.'
      @weapon = weapon if @prompt.yes?('Are you sure?')

      Zarta::HUD.new(@dungeon)
    end

    def handle_enemy
      @current_enemy = @dungeon.room.enemy.name
      @current_enemy = @pastel.magenta.bold(@current_enemy)
      puts "There is a #{@current_enemy} in here!"

      until @dungeon.room.enemy.nil?
        # Zarta::HUD.new(dungeon)
        enemy_choice = @prompt.select('What do you want to do?') do |menu|
          menu.choice 'Fight!'
          menu.choice 'Flee!'
          menu.choice 'Look!'
        end

        fight if enemy_choice == 'Fight!'
        flee if enemy_choice == 'Flee!'
        @dungeon.room.enemy.inspect if enemy_choice == 'Look!'
      end
    end

    def flee
      return unless @prompt.yes?('Try to flee?')
      puts "You try to get away from the #{@current_enemy}"
      gets

      flee_hit
      @dungeon.room.enemy = nil
      gets
      Zarta::HUD.new(@dungeon)
    end

    def flee_hit
      @enemy = @dungeon.room.enemy
      level_difference = @dungeon.room.enemy.level - @level
      flee_chance = @dungeon.level + @level
      if rand(flee_chance) >= flee_chance + level_difference
        puts 'You are successful!'
        @dungeon.room.enemy = nil
        return
      else
        base = @enemy.weapon.damage + rand(@enemy.level) + @enemy.level
        enemy_hit = base.round
        enemy_hit_c = @pastel.red.bold(enemy_hit)
        @health[0] -= enemy_hit
        puts "The #{@current_enemy} hits you as you try to flee!"
        puts "You take #{enemy_hit_c} hits you as you flee!\n"
      end
    end

    def fight
      @enemy = @dungeon.room.enemy
      @enemy_c = @pastel.magenta.bold(@enemy.name)
      loop do
        Zarta::HUD.new(@dungeon)
        base_weapon_damage = @weapon.damage + rand(@weapon.damage)
        player_hit = base_weapon_damage + rand(@level) + @level
        player_hit_c = @pastel.bright_yellow.bold(player_hit)
        puts "You attack the #{@enemy_c}!"
        puts "You hit for #{player_hit_c} damage."

        if @enemy.take_damage(player_hit)
          enemy_killed(@enemy, @enemy_c)
          break
        end

        gets

        base = @enemy.weapon.damage + rand(@enemy.level) + @enemy.level

        enemy_hit = base.round

        enemy_hit_c = @pastel.red.bold(enemy_hit)
        puts "The #{@enemy_c} hits you!"
        puts "You take #{enemy_hit_c} damage."

        take_damage(enemy_hit)

        gets

      end
    end

    def take_damage(damage)
      @health[0] -= damage
      death if @health[0] <= 0
    end

    def death
      puts 'You have been killed!'
      puts "\n#{@pastel.bright_red.bold('GAME OVER')}"
      gets
      exit[0]
    end

    def enemy_killed(enemy, enemy_c)
      xp_gain = enemy.level + @level + @dungeon.level
      xp_gain_c = @pastel.bright_white.bold(xp_gain)
      puts "You have slain the #{enemy_c}!"
      puts "You are victorious!\n"
      puts "You gain #{xp_gain_c} Experience."

      gain_xp(xp_gain)

      @dungeon.room.weapon = enemy.weapon
      @dungeon.room.enemy = nil
      gets

      Zarta::HUD.new(@dungeon)
    end

    def gain_xp(xp)
      @xp += xp
      return unless @xp >= @level * 10
      @level += 1
      @xp = 0
      puts @pastel.bright_blue.bold('You gain a level!')
      puts "You are now level #{@pastel.bright_blue.bold(@level)}"
      health = health_increase
      puts 'Your health is replenished!'
      puts "You gain #{@pastel.bright_green.bold(health)} to max health."
    end

    def health_increase
      base = (@level - 1) + @dungeon.level
      increase = rand(base..base * 3)
      @health[1] += increase
      @health[0] = @health[1]
      increase
    end
  end
end
