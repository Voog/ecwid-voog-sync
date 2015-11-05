class Product < ActiveRecord::Base
  include ModelMetainfo

  belongs_to :category, foreign_key: 'ecwid_category_id', primary_key: 'ecwid_id'

  after_destroy :remove_remote_object

  def remove_remote_object
    ApiParser::Voog.new.delete_element(voog_element_id) if voog_element_id.present?
  end

  def voog_position=(value)
    set_metadata(:voog_position, value)
  end

  def voog_position
    get_metadata(:voog_position)
  end
end
