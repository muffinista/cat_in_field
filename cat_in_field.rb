#!/usr/bin/env ruby

require 'rubygems'
require 'chatterbot/dsl'
require 'twitter-text'

#
# this is the script for the twitter bot cat_in_field
# generated on 2016-02-29 13:24:01 -0500
#
  
GRID_W = 10
GRID_H = 10

MIN_FLOWERS = 4
MAX_FLOWERS = 10

MIN_ACTORS = 2
MAX_ACTORS = 4

MIN_FILLER = 1
MAX_FILLER = 10

ACTOR_TYPES = [:chick, :turtle, :snake, :bug, :beetle, :bee, :spider]
FLOWER_TYPES = [:sunflower, :rose, :blossom, :spider_web]
FILLER_TYPES = [:shamrock, :rice, :herb]

CAT_EMOJI = [:cat, :cat_face, :cat_smirk, :cat_pout, :cat_grin, :cat_smile]

GRASS = :seedling

EMOJI = {
  :cat => Twitter::Unicode::U1F408,
  :cat_face => Twitter::Unicode::U1F431,
  :cat_smirk => Twitter::Unicode::U1F63C,
  :cat_pout => Twitter::Unicode::U1F63E,
  :cat_grin => Twitter::Unicode::U1F638,
  :cat_smile => Twitter::Unicode::U1F63A,
  :seedling => Twitter::Unicode::U1F331,
  :chick => Twitter::Unicode::U1F425,
  :turtle => Twitter::Unicode::U1F422,
  :snake => Twitter::Unicode::U1F40D,
  :bug => Twitter::Unicode::U1F41B,
  :beetle => Twitter::Unicode::U1F41E,
  :bee => Twitter::Unicode::U1F41D,
  :spider => Twitter::Unicode::U1F577,
  :spider_web => Twitter::Unicode::U1F578,
  :sunflower => Twitter::Unicode::U1F33B,
  :rose => Twitter::Unicode::U1F339,
  :blossom => Twitter::Unicode::U1F33C,
  :shamrock => Twitter::Unicode::U2618,
  :rice => Twitter::Unicode::U1F33E,
  :herb => Twitter::Unicode::U1F33F
}




CAT_STATES = [:napping, :hunting, :playing]
NON_CAT_STATES = [:napping, :playing]

STATE_CHANGE = 0.4

@rng = Random.new

def init_new_grid
  output = []
  total = GRID_W * GRID_H

  (MIN_FLOWERS..@rng.rand(MIN_FLOWERS..MAX_FLOWERS)).each { output << FLOWER_TYPES.sample }
  (MIN_FILLER..@rng.rand(MIN_FILLER..MAX_FILLER)).each { output << FILLER_TYPES.sample }  

  (total-1).downto(output.length).each { output << GRASS }

  output.shuffle
end


def init_cat
  {
    x: @rng.rand(0..GRID_W),
    y: @rng.rand(0..GRID_H),
    state: CAT_STATES.sample,
    avatar: CAT_EMOJI.sample
  }
end

def init_actors
  (MIN_ACTORS..@rng.rand(MIN_ACTORS+1..MAX_ACTORS)).collect {
    {
      type: ACTOR_TYPES.sample,
      x: @rng.rand(0..GRID_W),
      y: @rng.rand(0..GRID_H),
      state: NON_CAT_STATES.sample
    }
  }
end

def pretty_format(data, actors, cat)
  base = data.dup

  cat_pos = (cat[:y]*GRID_H) + cat[:x]
  puts "PUTTING CAT AT #{cat.inspect} -> #{cat_pos}"
  base[cat_pos] = :cat

  actors.each { |a|
    pos = (a[:y]*GRID_H) + a[:x]
    puts "PUTTING #{a[:type]} AT #{a.inspect} -> #{pos}"
    base[pos] = a[:type]
  }

  base.collect { |x| EMOJI[x] }.each_slice(GRID_W).to_a.collect { |l| l.join("") }.join("\n")
end

def update_actor(a, states=[CAT_STATES])
  if @rng.rand <= STATE_CHANGE
    a[:state] = states.sample
    puts "ACTOR IS CHANGING to #{a[:state]}"
  else
    puts "ACTOR IS #{a[:state]}"
  end

  if a[:state] != :napping
    tmp_x = 0
    tmp_y = 0
    while tmp_x == 0 && tmp_y == 0
      tmp_x = [-1, 0, 1].sample
      tmp_y = [-1, 0, 1].sample
    end

    tmp_x = a[:x] + tmp_x
    tmp_y = a[:y] + tmp_y
    
    if tmp_x < 0
      tmp_x = GRID_W - 1
    elsif tmp_x >= GRID_W
      tmp_x = 0
    end

    if tmp_y < 0
      tmp_y = GRID_H - 1
    elsif tmp_y >= GRID_H
      tmp_y = 0
    end
    
    a[:x] = tmp_x
    a[:y] = tmp_y

    puts a.inspect
  else
    puts a.inspect
  end
  a
end

@data = bot.config[:data] || init_new_grid
@cat = bot.config[:cat] || init_cat
@actors = bot.config[:actors] || init_actors

@count = bot.config[:count] || 0

MIN_TWEETS = 10

if ENV['RESET'] || @count > MIN_TWEETS && rand >= 0.7
  puts "RESET"
  @data = init_new_grid
  @cat = init_cat
  @actors = init_actors
  @count = 0
else
  @count = @count + 1
end

verbose

@cat[:avatar] ||= CAT_EMOJI.sample

if ENV['debug']
  while true
    system("clear")
    
    @actors = @actors.collect { |a|
      update_actor(a, NON_CAT_STATES)
    }

    # run cat last. cat is always on top!
    @cat = update_actor(@cat)
    if @rng.rand > 0.85
      @cat[:avatar] = CAT_EMOJI.sample
    end
  
    puts pretty_format(@data, @actors, @cat)

    sleep 0.5
  end
else

  @actors = @actors.collect { |a|
    update_actor(a, NON_CAT_STATES)
  }

  # run cat last. cat is always on top!
  @cat = update_actor(@cat) 
  if @rng.rand > 0.85
    @cat[:avatar] = CAT_EMOJI.sample
  end
  
  output = pretty_format(@data, @actors, @cat)
  puts output
  puts output.length
  tweet output
  
  bot.config[:data] = @data
  bot.config[:cat] = @cat
  bot.config[:actors] = @actors
  bot.config[:count] = @count
end
