# frozen_string_literal: true

class LicensesFinder
  def initialize(params)
    @params = params
  end

  def execute
    items = License.all

    items = by_id(items)
    items = order(items)

    items
  end

  private

  attr_reader :params

  def by_id(items)
    return items unless params[:id]

    items.by_id(params[:id])
  end

  def order(items)
    return items unless params[:sort]

    items.order_by(params[:sort])
  end
end
