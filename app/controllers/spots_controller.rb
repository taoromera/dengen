class SpotsController < ApplicationController
  
  def get_spots
    spots = Spot.new
    res = spots.get_spots(params)
    render :json => ActiveSupport::JSON.encode({:results => res, :status => "ok"})   

  end

  def up_comment
    spot = Spot.new
    res = spot.up_comment(params)
    render :json => ActiveSupport::JSON.encode(res)
  end

  def up_goodbad
    spot = Spot.new
    res = spot.up_goodbad(params)
    render :json => ActiveSupport::JSON.encode(res)
  end

  def add_new_spot
    spot = Spot.new
    res = spot.add_new_spot(params)
    render :json => ActiveSupport::JSON.encode(res)
  end
end
