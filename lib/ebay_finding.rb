require 'open-uri'

# class to ease retrieving data from the Ebay Finding API: http://developer.ebay.com/products/finding/
class EbayFinding
  
  # searches ebay (internally using the "findItemsAdvanced" method http://developer.ebay.com/DevZone/finding/CallRef/findItemsAdvanced.html )
  # requires an EbaySearchCriteria instance
  def search(criteria)
    params = {
      "outputSelector(0)"=>"AspectHistogram",
      "paginationInput.entriesPerPage" => criteria.entries_per_page,
      "sortOrder" => criteria.sort_order,
      "paginationInput.pageNumber" => criteria.page_number
    }
    if criteria.category_id
      params['categoryId'] = criteria.category_id
    end
    if criteria.keywords
      params['keywords'] = criteria.keywords
    end
    criteria.aspects.keys.each_index do |aspect_index|
      params["aspectFilter(#{aspect_index}).aspectName"] = criteria.aspects.keys[aspect_index]
      params["aspectFilter(#{aspect_index}).aspectValueName"] = criteria.aspects[criteria.aspects.keys[aspect_index]]
    end
    criteria.item_filters.each_index do |filter_index|
      item_filter = criteria.item_filters[filter_index]
      params["itemFilter(#{filter_index}).name"] = item_filter.name
      params["itemFilter(#{filter_index}).value"] = item_filter.value
      params["itemFilter(#{filter_index}).paramName"] = item_filter.paramName if item_filter.paramName
      params["itemFilter(#{filter_index}).paramValue"] = item_filter.paramValue if item_filter.paramValue
    end
    fetch(build_url("findItemsAdvanced", params))
  end
  
  # calls the "getHistograms" operation for a given category
  def histograms( category, extra_params = {})
    params = { "categoryId" => TOP_LEVEL_US_CATEGORIES[category]||category }.merge!(extra_params)
    fetch(build_url("getHistograms", params))
  end
  
  # calls the "getKeywordsRecommendations" operation for the provided keywords argument
  def keyword_recommendations(keywords, extra_params = {})
    fetch(build_url("getSearchKeywordsRecommendation", {'keywords'=>keywords}.merge!(extra_params)))
  end

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

  private
  
  def fetch(url)
    open(url, "UserAgent" => config_params[:user_agent]).read
  end

  def build_url(operation, operation_params = {})
    # build standard app_id and affiliate parameters
    params = STANDARD_PARAMETERS.keys.inject({}) { |params,key| params[STANDARD_PARAMETERS[key]] = config_params[key] if config_params[key]; params }
    # add operation parameter
    params['OPERATION-NAME'] = operation
    # add operation_params provided
    params.merge!(operation_params)
    "#{BASE_URL}#{params.keys.sort.inject(""){|string,key| "#{string}&#{key}=#{CGI.escape(params[key].to_s)}"}}"
  end
  
  # access to configuration parameters stored in ebay_finding.yml
  def config_params
    return @@config_params if @@config_params
    params = YAML.load_file("#{RAILS_ROOT}/config/ebay_finding.yml")
    @@config_params = params[RAILS_ENV.to_sym] || params[:production]
  end

  @@config_params = nil
  
  BASE_URL = "http://svcs.ebay.com/services/search/FindingService/v1?REST-PAYLOAD"

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

  STANDARD_PARAMETERS = {
    :app_id => "SECURITY-APPNAME",
    :affiliate_tracking_id => "affiliate.trackingId",
    :affiliate_network_id => "affiliate.networkId",
    :affiliate_custom_id => "affiliate.customId",
    :global_id => "GLOBAL-ID",
    :default_response_format => "RESPONSE-DATA-FORMAT"
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
class EbaySearchCriteria
  attr_accessor :category_id
  attr_accessor :keywords
  attr_accessor :aspects
  attr_accessor :item_filters
  attr_accessor :sort_order
  attr_accessor :entries_per_page
  attr_accessor :page_number

  def initialize
    @category_id = nil
    @keywords = nil
    @item_filters = []
    @aspects = {}
    @sort_order = "EndTimeSoonest"
    @page_number = 1
    @entries_per_page = 10
  end

end

# ItemFilter represents a single ItemFilter criterion
# see:
# http://developer.ebay.com/DevZone/finding/CallRef/types/ItemFilter.html
# http://developer.ebay.com/DevZone/finding/CallRef/types/ItemFilterType.html
class ItemFilter
  attr_accessor :name
  attr_accessor :value
  attr_accessor :paramName
  attr_accessor :paramValue
  
  def initialize(name, value, paramName=nil, paramValue=nil)
    @name = name
    @value = value
    @paramName = paramName
    @paramValue = paramValue
  end
end

# Item Filter Names
# * AvailableTo
# * BestOfferOnly
# * Condition
# * Currency
# * EndTimeFrom
# * EndTimeTo
# * ExcludeAutoPay
# * ExcludeCategory
# * ExcludeSeller
# * FeaturedOnly
# * FeedbackScoreMax
# * FeedbackScoreMin
# * FreeShippingOnly
# * GetItFastOnly
# * HideDuplicateItems
# * ListingType
# * LocalPickupOnly
# * LocalSearchOnly
# * LocatedIn
# * LotsOnly
# * MaxBids
# * MaxDistance
# * MaxPrice
# * MaxQuantity
# * MinBids
# * MinPrice
# * MinQuantity
# * ModTimeFrom
# * PaymentMethod
# * Seller
# * SellerBusinessType
# * SoldItemsOnly
# * TopRatedSellerOnly
# * WorldOfGoodOnly
