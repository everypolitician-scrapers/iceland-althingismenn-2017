#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    noko.css('.mw-parser-output').xpath('.//p[a]').map { |p| fragment(p => MemberRow) }.map(&:to_h)
  end
end

class MemberRow < Scraped::HTML
  field :name do
    name_link.text.tidy
  end

  field :wikidata do
    name_link.attr('wikidata')
  end

  field :party do
    party_link.text.tidy
  end

  field :party_wikidata do
    party_link.attr('wikidata')
  end

  field :constituency do
    constituency_field.text
  end

  field :constituency_wikidata do
    constituency_field.css('a/@wikidata').text
  end

  private

  def name_link
    noko.css('a').first
  end

  def party_link
    noko.css('a').last
  end

  def constituency_field
    noko.xpath('preceding::h2').last.css('.mw-headline')
  end
end

url = 'https://is.wikipedia.org/wiki/Kj%C3%B6rnir_al%C3%BEingismenn_2017'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])
