module ModelMetainfo
  extend ActiveSupport::Concern

  included do
    serialize :metainfo, JSON
  end

  protected

  # Set key-value pair in metainfo field
  def set_metadata(key, value)
    if metainfo.is_a?(Hash)
      metainfo[key.to_s] = value
    else
      self.metainfo = {key.to_s => value}
    end
  end

  # Retrieve value from metainfo field
  def get_metadata(key)
    metainfo.try(:[], key.to_s) if respond_to?(:metainfo) && metainfo.is_a?(Hash)
  end
end
