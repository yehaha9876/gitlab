module BreadcrumbsHelper
  def add_to_breadcrumbs(text, link)
    @breadcrumbs_extra_links ||= []
    @breadcrumbs_extra_links.push({
      text: text,
      link: link
    })
  end

  def breadcrumb_title_link
    return @breadcrumb_link if @breadcrumb_link

    if controller.available_action?(:index)
      url_for(action: "index")
    else
      request.path
    end
  end

  def breadcrumb_title(title)
    return if defined?(@breadcrumb_title)

    @breadcrumb_title = title
  end

  def breadcrumb_list_item(link)
    content_tag "li" do
      link + icon("angle-right", class: "breadcrumbs-list-angle")
    end
  end

  def add_to_breadcrumb_dropdown(link, location: :before)
    @breadcrumb_dropdown_links ||= {}
    @breadcrumb_dropdown_links[location] ||= []
    @breadcrumb_dropdown_links[location] << link
  end
end
