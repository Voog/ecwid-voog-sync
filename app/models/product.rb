class Product < ActiveRecord::Base
  belongs_to :catrgory, foreign_key: 'ecwid_catrgory_id', primary_key: 'ecwid_id'
  after_destroy :remove_remote_object

  def remove_remote_object
    ApiParser::Voog.new.delete_element(voog_element_id) if voog_element_id.present?
  end
end
