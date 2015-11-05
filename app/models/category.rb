class Category < ActiveRecord::Base
  include ModelMetainfo

  has_many :products, primary_key: 'ecwid_id', foreign_key: 'ecwid_category_id'

  def voog_node_id=(value)
    set_metadata(:voog_node_id, value)
  end

  def voog_node_id
    get_metadata(:voog_node_id)
  end
end
