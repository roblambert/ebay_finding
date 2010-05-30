require 'open-uri'
require 'json'

# module to ease retrieving data from the Ebay Finding API: http://developer.ebay.com/products/finding/
module EbayFinding
  
  # Item sort options. See http://developer.ebay.com/devzone/finding/CallRef/findItemsByKeywords.html#Request.sortOrder
  SORT_OPTIONS = {
    :best_match => "BestMatch", # 	Sorts items by Best Match, which is based on community buying activity and other relevance-based factors (default sort for most methods)
    :bid_count_fewest => "BidCountFewest",  #Sorts items by the number of bids they have received, with items that have received the fewest bids first. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :bid_count_most => "BidCountMost", # Sorts items by the number of bids they have received, with items that have received the most bids first. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :country_ascending => "CountryAscending", # Sorts items available on the the given site (as specified by global ID in the HTTP header or URL parameter) by the country in which they are located. For CountryAscending, items located in the country most closely associated with the site appear first, followed by items in related countries, and then items from other countries. CountryAscending applies to the following sites only: Austria (EBAY-AT), Belgium-French (EBAY-FRBE), Belgium-Netherlands (EBAY-NLBE), Germany (EBAY-DE), Ireland (EBAY-IE), Netherlands (EBAY-NL), Poland (EBAY-PL), Spain (EBAY-ES), and Switzerland (EBAY-CH). 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :country_descending => "CountryDescending", #Sorts items available on the the given site (as specified by global ID in the HTTP header or URL parameter) by the country in which they are located. For CountryDescending, items are sorted in reverse order of CountryAscending. That is, items in countries not specifically related to the site appear first, sorted in descending alphabetical order by English country name. For example, when searching the Ireland site, items located in countries like Yugoslavia or Uganda are returned first. Items located in Ireland (IE) will be returned last.
    :current_price_highest => "CurrentPriceHighest", #	Sorts items by their current price, with the highest price first. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :distance_nearest => "DistanceNearest", #	Sorts items by distance from the buyer in ascending order. The request must also include a buyerPostalCode. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :end_time_soonest => "EndTimeSoonest", # Sorts items by end time, with items ending soonest listed first. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :price_plus_shipping_highest => "PricePlusShippingHighest", # Sorts items by the combined cost of the item price plus the shipping cost, with highest combined price items listed first. Items are returned in the following groupings: highest total-cost items (for items where shipping was properly specified) appear first, followed by freight- shipping items, and then items for which no shipping was specified. Each group is sorted by price. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :price_plus_shipping_lowest => "PricePlusShippingLowest", # Sorts items by the combined cost of the item price plus the shipping cost, with the lowest combined price items listed first. Items are returned in the following groupings: lowest total-cost items (for items where shipping was properly specified) appear first, followed by freight- shipping items, and then items for which no shipping was specified. Each group is sorted by price. 	findItemsAdvanced, findItemsByCategory, findItemsByKeywords, findItemsByProduct, findItemsIneBayStores
    :start_time_newest => "StartTimeNewest" # Sorts items by the start time, the most recently listed (newest) items appear first.
  }
  
  # top level category ids for U.S., pulled from Trading API May 28, 2010
  TOP_LEVEL_US_CATEGORIES = {
    :antiques=>"20081",
    :art=>"550",
    :baby=>"2984",
    :books=>"267",
    :business_and_industrial=>"12576",
    :camera_and_photo=>"625",
    :cell_phones=>"15032",
    :clothing_shoes_and_accesories=>"11450",
    :coins_and_paper_money=>"11116",
    :collectibles=>"1",
    :computers_and_networking=>"58058",
    :crafts=>"14339",
    :dolls_and_bears=>"237",
    :dvds_and_movies=>"11232",
    :electronics=>"293",
    :gift_certificates=>"31411",
    :health_and_beauty=>"26395",
    :home_and_garden=>"11700",
    :jewelry_and_watches=>"281",
    :music=>"11233",
    :musical_instruments=>"619",
    :pet_supplies=>"1281",
    :pottery_and_glass=>"870",
    :real_estate=>"10542",
    :specialty_services=>"316",
    :sporting_goods=>"382",
    :sports_mem_cards_and_fan_shop=>"64482",
    :stamps=>"260",
    :tickets=>"1305",
    :toys_and_hobbies=>"220",
    :travel=>"3252",
    :video_games=>"1249",
    :everything_else=>"99",
    :partner=>"10159"
  }
  
  # calls the "findItemsAdvanced" operation and returns the 'findItemsAdvancedResponse' JSON as a Hash.
  # aims to make it easy to search by keyword and category as that's the most common search that I perform!
  # extra_params are used explicitly in the request and override any base parameters including app_id, affiliate keys, etc.  
  def self.find_advanced( keywords, category, numResults = 5, sort = :end_time_soonest, extra_params = {} )
    params = {
      "paginationInput.entriesPerPage" => numResults,
      "sortOrder" => SORT_OPTIONS[sort]||sort
    }
    params['keywords'] = keywords if keywords
    params['categoryId'] = TOP_LEVEL_US_CATEGORIES[category]||category if TOP_LEVEL_US_CATEGORIES[category]||category
    params.merge!(extra_params)
    fetch_as_json(build_url(:find_advanced, params))['findItemsAdvancedResponse']
  end
  
  # calls the "getHistograms" operation for a given category and returns the 'getHistogramsResponse' JSON as a Hash
  def self.histograms( category, extra_params = {})
    params = { "categoryId" => TOP_LEVEL_US_CATEGORIES[category]||category }.merge!(extra_params)
    fetch_as_json(build_url(:histograms, params))['getHistogramsResponse']
  end
  
  # calls the "getKeywordsRecommendations" operation for the provided keywords argument and returns the 'getSearchKeywordsRecommendationResponse' JSON as a Hash
  def self.keyword_recommendations(keywords, extra_params = {})
    fetch_as_json(build_url(:keyword_recommendations, {'keywords'=>keywords}.merge!(extra_params)))['getSearchKeywordsRecommendationResponse']
  end

  private

  def self.fetch_as_json(url)
    JSON.parse( open(url, "UserAgent" => config_params[:user_agent]).read )
  end

  def self.build_url(operation, operation_params = {})
    # build standard app_id and affiliate parameters
    params = STANDARD_PARAMETERS.keys.inject({}) { |params,key| params[STANDARD_PARAMETERS[key]] = config_params[key] if config_params[key]; params }
    # add operation parameter
    params['OPERATION-NAME'] = OPERATIONS.fetch(operation) || operation
    # add operation_params provided
    params.merge!(operation_params)
    "#{BASE_URL}#{params.keys.inject(""){|string,key| "#{string}&#{key}=#{CGI.escape(params[key].to_s)}"}}"
  end
  
  # access to configuration parameters stored in ebay-finding.yml
  def self.config_params
    return @@config_params if @@config_params
    params = YAML.load_file("#{RAILS_ROOT}/config/ebay_finding.yml")
    @@config_params = params[RAILS_ENV.to_sym] || params[:production]
  end

  @@config_params = nil
  
  BASE_URL = "http://svcs.ebay.com/services/search/FindingService/v1?RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD"

  OPERATIONS = {
    :keyword_recommendations => "getSearchKeywordsRecommendation", # Get recommended keywords for search
    :find_by_keywords => "findItemsByKeywords", # Search items by keywords
    :find_by_category => "findItemsByCategory", # Search items in a category
    :find_advanced => "findItemsAdvanced", # Advanced search capabilities
    :find_by_product_id => "findItemsByProduct", # Search items by a product identifier
    :find_in_store => "findItemsIneBayStores", # Search items in stores
    :histograms => "getHistograms" # Get category and domain meta data
  }

  STANDARD_PARAMETERS = {
    :app_id => "SECURITY-APPNAME",
    :affiliate_tracking_id => "affiliate.trackingId",
    :affiliate_network_id => "affiliate.networkId",
    :affiliate_custom_id => "affiliate.customId",
    :global_id => "GLOBAL-ID"
  }

  # GLOBAL_IDS = {
  #   "EBAY-AT" => "eBay Austria",
  #   "EBAY-AU" => "eBay Australia",
  #   "EBAY-CH" => "eBay Switzerland",
  #   "EBAY-DE" => "eBay Germany",
  #   "EBAY-ENCA" => "eBay Canada (English)",
  #   "EBAY-ES" => "eBay Spain",
  #   "EBAY-FR" => "eBay France",
  #   "EBAY-FRBE" => "eBay Belgium (French)",
  #   "EBAY-FRCA" => "eBay Canada (French)",
  #   "EBAY-GB" => "eBay UK",
  #   "EBAY-HK" => "eBay Hong Kong",
  #   "EBAY-IE" => "eBay Ireland",
  #   "EBAY-IN" => "eBay India",
  #   "EBAY-IT" => "eBay Italy",
  #   "EBAY-MOTOR" => "eBay Motors",
  #   "EBAY-MY" => "eBay Malaysia",
  #   "EBAY-NL" => "eBay Netherlands",
  #   "EBAY-NLBE" => "eBay Belgium (Dutch)",
  #   "EBAY-PH" => "eBay Philippines",
  #   "EBAY-PL" => "eBay Poland",
  #   "EBAY-SG" => "eBay Singapore",
  #   "EBAY-US" => "eBay United States"
  # }

end