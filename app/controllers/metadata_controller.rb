# frozen_string_literal: true

class MetadataController < ApplicationController
  skip_before_action :authenticate!

  def show
    render xml: to_xml, content_type: "application/samlmetadata+xml"
  end

  private

  def to_xml
    Rails.cache.fetch(metadata_url, expires_in: 1.hour) do
      Idp.default(request).to_xml
    end
  end
end
