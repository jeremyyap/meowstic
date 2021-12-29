#!/usr/bin/ruby
require 'csv'
require 'nokogiri'
require 'byebug'

def is_header_node?(node)
  node.name === 'p' && node.inner_text.start_with?("<strong>")
end

def is_numbered_list_item?(node)
  node.name === 'p' && (node.inner_text =~ /^[0-9]+\./) === 0
end

def build_numbered_list(node)
  node.add_previous_sibling(Nokogiri::XML::Node.new('ol', node.document)) unless node.previous_sibling&.name == 'ol'
  ol = node.previous_sibling
  li = Nokogiri::XML::Node.new('li', node.document)
  sibling = node.next_sibling
  li.parent = ol
  node.parent = li

  until sibling === nil || is_header_node?(sibling) || is_numbered_list_item?(sibling)
    next_sibling = sibling.next_sibling
    sibling.parent = li
    sibling = next_sibling
  end
end

CSV.open('input.csv', 'r', headers: true) do |input|
  data = input.read
  CSV.open('output.csv', 'w+', write_headers: true, headers: data.headers) do |output|
    data.each do |row|
      stack = []
      doc = Nokogiri::HTML::DocumentFragment.parse(row['longDescription'])
      stack.push(doc)

      while !stack.empty?
        node = stack.pop
        stack += node.children.reverse
        build_numbered_list(node) if is_numbered_list_item?(node)
      end

      puts doc
      output << row
    end
  end
end
