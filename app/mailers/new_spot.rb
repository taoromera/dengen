class NewSpot < ActionMailer::Base
  default from: "taoromera@gmail.com"

  def send_new_spot_notif(spot)

    @spot = spot
    mail(:to => '<taoromera@gmail.com>, <shingo.hiranuma@gmail.com>', :subject => "[Battery Cafe] New spot added")
  end

end
