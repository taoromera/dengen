#!/bin/env ruby
# encoding: utf-8

class Spot < ActiveRecord::Base
  attr_accessible :address, :active, :bads, :category, :eigyo_jikan, :goods, :location, :name, :other, :own, :tags, :tel, :website, :wireless
  has_many :comments
  has_many :goodbads

  def get_spots(params)
      
      n = params[:lat].to_f +  0.01
      s = params[:lat].to_f -  0.01
      w = params[:lon].to_f -  0.01
      e = params[:lon].to_f +  0.01
      search_box = {:n => n, :w => w, :s => s, :e => e}
      res = JSON.parse(Typhoeus::Request.get('http://oasis.mogya.com/api/v0/search', :params => search_box).body)
      spots = res["results"]

      # Store spots in local DB
      cache_spots(spots, search_box)

      # Clean response to return only useful fields AND add comments
      res = clean_response(res)

      # Add proprietary spots to the reponse
      res = add_own_spots(res, search_box)

      return(res)
  end

  def clean_response(res)

    res["results"].each do |spot|
      spot["eigyo_jikan"] = find_eigyo_jikan(spot["other"])
      spot["name"] = spot["title"]
      spot["website"] = spot["url_pc"]
      spot.except!("entry_id", "wireless", "powersupply", "other", "tag", "url_title", "status", "edit_date", "category", "mo_url", "icon", "icon_powerframe", "title", "url_pc")
      spot_id = find_spot_id_from_lonlat(spot["longitude"], spot["latitude"])
      spot["id"] = spot_id

      # Add comments for this spot
      spot["comments"] = Spot.find(spot_id).comments
    end

  end

  def find_spot_id_from_lonlat(lon, lat)
      spot_id = Spot.connection.execute("SELECT id FROM spots WHERE ST_X(location) = #{lon} AND ST_Y(location) = #{lat}").getvalue(0,0)
  end

  def add_own_spots(res, search_box)
    
    # Retrieve spots from the DB in the searched area
    db_spots = Spot.connection.execute("SELECT name, website, eigyo_jikan, goods, bads, ST_X(location) as lon, ST_Y(location) as lat, id FROM spots WHERE location && ST_MakeEnvelope(#{search_box[:w]},#{search_box[:s]},#{search_box[:e]},#{search_box[:n]}) AND own=true").values

    # Add proprietary spots to the results hash
    db_spots.each do |db_spot|
      res.push [{"name" => db_spot[0], 
                "website" => db_spot[1], 
                "eigyo_jikan" => db_spot[2], 
                "goods" => db_spot[3], 
                "bads" => db_spot[4], 
                "longitude" => db_spot[5],
                "latitude" => db_spot[6],
                "id" => db_spot[7],
                "comments" => Spot.find(db_spot[7]).comments}]
    end
   
    return res
  end

  def cache_spots(spots, search_box)
    
    # Retrieve spots from the DB in the searched area
    db_spots = Spot.connection.execute("SELECT ST_X(location), ST_Y(location) FROM spots WHERE location && ST_MakeEnvelope(#{search_box[:w]},#{search_box[:s]},#{search_box[:e]},#{search_box[:n]})").values

    # Create array with spots to save to DB
    spots_to_save = Array.new(spots) 

    # Determine spots to save to the DB 
    spots.each do |spot|
      # Round lat and lon to match the DB precision
      spot["longitude"] = spot["longitude"].to_f.round(12).to_s
      spot["latitude"] = spot["latitude"].to_f.round(12).to_s
      # If spot in the same location already exists in the DB, skip
      db_spots.each do |db_spot|
        spot["longitude"] == db_spot[0] && spot["latitude"] == db_spot[1] ? spots_to_save.delete(spot) : 1
      end
    end

    # Save spots in DB
    spots_to_save.each do |spot|
      id = Spot.create(:address => spot["address"], 
                  :active => '1', 
                  :bads => 0, 
                  :category => spot["category"], 
                  :eigyo_jikan => find_eigyo_jikan(spot["other"]), 
                  :goods => 0, 
                  :name => spot["title"],
                  :other => spot["other"],
                  :own => '0',
                  :tags => spot["tag"],
                  :tel => spot["tel"],
                  :website => spot["url_pc"],
                  :wireless => spot["wireless"]).id

       # Enter the location as a GIS object
       Spot.connection.execute("UPDATE spots SET location = ST_GeometryFromText('POINT(#{spot["longitude"]} #{spot["latitude"]})', 4326) WHERE id=#{id}")

    end

  end 

  def up_comment(params)
    Spot.find(params[:id]).comments.create(:content => params[:content]) 
  end

  def up_goodbad(params)
 
    params[:good] == "0" ? params[:good] = false : params[:good] = true

    spot = Spot.find(params[:spot_id])
    gb = Spot.find(params[:spot_id]).goodbads

    # If we still don't have any records, create the first one and return
    if gb.empty? 
      gb.create(:token => params[:token], :good => params[:good])
      params[:good] == true ? spot.increment!(:goods) : spot.increment!(:bads)
      return
    end 

    # Has this user already reviewed this spot?
    double_review = gb.where(:token => params[:token])

    if double_review.empty?
      gb.create(:token => params[:token], :good => params[:good]) 
      params[:good] == true ? spot.increment!(:goods) : spot.increment!(:bads)
      return "Created entry"
    elsif double_review[0].good == params[:good]
      return "Double review"
    else
      double_review[0].update_attributes(:good => params[:good])
      if params[:good] == false
        spot.decrement!(:goods)
        spot.increment!(:bads)
      else
        spot.decrement!(:bads)
        spot.increment!(:goods)
      end
      return "Changed to #{double_review[0].good}"
    end
  end


private

  def find_eigyo_jikan(text)

      eigyo_jikan = text.match('営業時間.*</dd>')

      if eigyo_jikan.nil?
        eigyo_jikan = ''
      else
        # Remove unnecessary HTML
        eigyo_jikan = eigyo_jikan[0]
        eigyo_jikan.gsub!('営業時間','')
        eigyo_jikan.gsub!('<dd>','')
        eigyo_jikan.gsub!('</dt>','')
        eigyo_jikan.gsub!('</dd>','')
        eigyo_jikan.gsub!('<br />','\n')
        eigyo_jikan.gsub!('<br/>','\n')
        eigyo_jikan.sub!(/\\n$/,'')
      end

    return eigyo_jikan
  end

end
