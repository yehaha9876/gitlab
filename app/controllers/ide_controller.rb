# frozen_string_literal: true

class IdeController < ApplicationController
  prepend EE::IdeController

  layout 'fullscreen'

  def index
  end
end
