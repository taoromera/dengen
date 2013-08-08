ActiveAdmin.register Spot do

  index do
    columns_to_exclude = ["location"]
    (Spot.column_names - columns_to_exclude).each do |c|
      column c.to_sym
    end
    default_actions
   end
  
  form do |f| 
    f.inputs "Spot" do   
      f.input :name
      f.input :address
      f.input :tel
      f.input :wireless
      f.input :category
      f.input :website
      f.input :tags
      f.input :other
      f.input :goods
      f.input :bads
      f.input :eigyo_jikan
      f.input :active
      f.input :own
    end
    f.actions
  end
 
end
