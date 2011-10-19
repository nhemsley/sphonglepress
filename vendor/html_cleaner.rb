require 'hpricot'

class HTMLCleaner
  def initialize(html, options = nil)
    @html = html
    @doc = Hpricot(@html)
    @options = options
  end

  def remove_attr(attr)
    @doc.search("[@#{attr}]").each do |e|
      e.remove_attribute(attr)
    end
  end

  def remove_tag(tag)
    els = @doc.search(tag)
    els.collect!{|node| node if node.children == nil}.compact.remove
    
    @doc.search(tag).each do |e|
      inner = e.children
      parent = e.parent
      if inner
        parent.replace_child(e, inner)
      end
    end
  end
  
  def remove_nested_empty_tags(first, second)
    els = @doc.search(first)
    remove = els.select do |el|
      ret = true
      ret = false unless el.children.detect {|ch| ch.name == second && ch.inner_html.chomp == ""}
      ret
    end
    remove.each {|r| r.parent.children.delete(r) }
  end

  def render
    @options[:remove_attrs].each { |a| remove_attr a } if @options[:remove_attrs]
    @options[:remove_tags].each { |a| remove_tag a } if @options[:remove_tags]
    @options[:remove_nested_empty_tags].each { |a| remove_nested_empty_tags(a[0], a[1]) } if @options[:remove_nested_empty_tags]

    @doc.to_s
  end
end