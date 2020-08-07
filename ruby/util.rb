#!/usr/bin/env ruby
# Encoding: utf-8
#
# Copyright:: Copyright 2020 Google LLC
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# Common utilities used by the Authorized Buyers Real-time Bidding API samples.

require 'optparse'
require 'google/apis/pubsub_v1'
require 'google/apis/realtimebidding_v1'
require 'google/apis/options'
require 'googleauth/service_account'


REALTIME_BIDDING_V1 = 'v1'
DEFAULT_VERSION = REALTIME_BIDDING_V1
SUPPORTED_RTB_API_VERSIONS = [REALTIME_BIDDING_V1]

# The JSON key file for your Service Account found in the Google Developers
# Console.
KEY_FILE = 'path_to_key'  # Path to JSON file containing your private key.

# The maximum number of results to be returned in a page for any list response.
MAX_PAGE_SIZE = 50


# Handles authentication and initializes the client.
def get_service(version=DEFAULT_VERSION)
  if !SUPPORTED_RTB_API_VERSIONS.include? version
    raise ArgumentError, 'Unsupported version (#{version}) of the Real-Time Bidding API specified!'
  end

  Google::Apis::ClientOptions.default.application_name =
      "Ruby Real-Time Bidding API samples: #{$0}"
  Google::Apis::ClientOptions.default.application_version = "1.0.0"

  if version == REALTIME_BIDDING_V1
    service = Google::Apis::RealtimebiddingV1::RealtimeBiddingService.new
  end

  auth_options = {
    :json_key_io => File.open(KEY_FILE, "r"),
    :scope => "https://www.googleapis.com/auth/realtime-bidding"
  }

  authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      options=auth_options)
  service.authorization = authorization
  service.authorization.fetch_access_token!

  return service
end


# Handles authentication and initializes a Google Cloud Pub/Sub client.
def get_cloud_pub_sub_service()
  Google::Apis::ClientOptions.default.application_name =
      "Ruby Real-Time Bidding API samples: #{$0}"
  Google::Apis::ClientOptions.default.application_version = "1.0.0"

  service = Google::Apis::PubsubV1::PubsubService.new

  auth_options = {
    :json_key_io => File.open(KEY_FILE, "r"),
    :scope => "https://www.googleapis.com/auth/pubsub"
  }

  authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      options=auth_options)
  service.authorization = authorization
  service.authorization.fetch_access_token!

  return service
end


def print_creative(creative)
  puts "* Creative ID: #{creative.creative_id}"

  unless creative.version.nil?
    puts "\t- Version: #{creative.version}"
  end

  puts "\t- Creative format: #{creative.creative_format}"

  serving_decision = creative.creative_serving_decision

  puts "\t- Creative Serving Decision"
  puts "\t\tDeals Serving Status: #{serving_decision.deals_serving_status.status}"
  puts "\t\tOpen Auction Serving Status: #{serving_decision.open_auction_serving_status.status}"
  puts "\t\tChina Serving Status: #{serving_decision.china_serving_status.status}"
  puts "\t\tRussia Serving Status: #{serving_decision.russia_serving_status.status}"

  unless creative.declared_click_through_urls.nil?
    puts "\t- Declared Click-Through URLs:"
    creative.declared_click_through_urls.each do |declared_click_url|
      puts "\t\t#{declared_click_url}"
    end
  end

  unless creative.declared_attributes.nil?
    puts "\t- Declared Attributes:"
    creative.declared_attributes.each do |declared_attribute|
      puts "\t\t#{declared_attribute}"
    end
  end

  unless creative.declared_vendor_ids.nil?
    puts "\t- Declared Vendor IDs:"
    creative.declared_vendor_ids.each do |declared_vendor_id|
      puts "\t\t#{declared_vendor_id}"
    end
  end

  unless creative.declared_restricted_categories.nil?
    puts "\t- Declared Restricted Categories:"
    creative.declared_restricted_categories.each do |declared_restricted_category|
      puts "\t\t#{declared_restricted_category}"
    end
  end

  html = creative.html
  unless html.nil?
    puts "\t- HTML creative contents:"
    puts "\t\tSnippet: #{html.snippet}"
    puts "\t\tHeight: #{html.height}"
    puts "\t\tWidth: #{html.width}"
  end
  native = creative.native
  unless native.nil?
    puts "\t- Native creative contents:"
    puts "\t\tHeadline: #{native.headline}"
    puts "\t\tBody: #{native.body}"
    puts "\t\tCallToAction: #{native.call_to_action}"
    puts "\t\tAdvertiser Name: #{native.advertiser_name}"
    puts "\t\tStar Rating: #{native.star_rating}"
    puts "\t\tClick Link URL: #{native.click_link_url}"
    puts "\t\tClick Tracking URL: #{native.click_tracking_url}"
    puts "\t\tPrice Display Text: #{native.price_display_text}"

    image = native.image
    unless image.nil?
      puts "\t\tImage contents:"
      puts "\t\t\tURL: #{image.url}"
      puts "\t\t\tHeight: #{image.height}"
      puts "\t\t\tWidth: #{image.width}"
    end
    logo = native.logo
    unless logo.nil?
      puts "\t\tLogo contents:"
      puts "\t\t\tURL: #{logo.url}"
      puts "\t\t\tHeight: #{logo.height}"
      puts "\t\t\tWidth: #{logo.width}"
    end
    app_icon = native.app_icon
    unless app_icon.nil?
      puts "\t\tApp Icon contents:"
      puts "\t\t\tURL: #{app_icon.url}"
      puts "\t\t\tHeight: #{app_icon.height}"
      puts "\t\t\tWidth: #{app_icon.width}"
    end
  end
  video = creative.video
  unless video.nil?
    puts "\t- Video creative contents:"
    unless video.video_url.nil?
      puts "\t\tVideo URL: #{video.video_url}"
    end
    unless video.video_vast_xml.nil?
      puts "\t\tVideo VAST XML: #{video.video_vast_xml}"
    end
  end
end


# An option to be passed into the example via a command-line argument.
class Option

  # The long alias for the option; typically one or more words delimited by
  # underscores. Do not use "--help", as this is reserved for displaying help
  # information.
  attr_reader :long_alias

  # The symbol associated with this option when parsed; this is the long alias
  # converted to a symbol, and will be used to access the parsed value for the
  # option.
  attr_reader :symbol

  # The type used for type coercion.
  attr_reader :type

  # The text displayed for the option if the user passes the "-h" or "--help"
  # options to display help information for the sample.
  attr_reader :help_text

  # The short alias for the option; a single character. Do not use "-h", as
  # this is reserved for displaying help information.
  attr_reader :short_alias

  # An optional array of values to be used to validate a user-specified value
  # against.
  attr_reader :valid_values

  # The default value to use if the option is not specified as a command-line
  # argument.
  attr_reader :default_value

  # A boolean indicating whether it is required that the user configure the
  # option.
  attr_reader :required

  def initialize(long_alias, help_template, type: String,
      short_alias: nil, valid_values: nil, required: false,
      default_value: nil)

    @long_alias = long_alias
    @symbol = long_alias.to_sym

    if valid_values.nil?
      @help_text = help_template
    elsif !valid_values.kind_of?(Array)
      raise ArgumentError, 'The valid_values argument must be an Array.'
    else
      @valid_values = []
      valid_values.each do |valid_value|
        @valid_values << valid_value.upcase
      end

      @help_text = (
        help_template + " This can be set to: #{@valid_values.inspect}."
      )
    end

    @type = type
    @short_alias = short_alias
    @default_value = default_value
    @required = required
  end

  def get_option_parser_args()
    args = []

    if !short_alias.nil?
      args << "-#{@short_alias} #{@long_alias.upcase}"
    end

    args << "--#{@long_alias} #{@long_alias.upcase}"
    args << @type
    args << @help_text

    return args
  end
end


# Parses arguments for the given Options.
class Parser
  def initialize(options)
    @parsed_args = {}
    @options = options
    @opt_parser = OptionParser.new do |opts|
      options.each do |option|
        opts.on(*option.get_option_parser_args()) do |x|
          unless option.valid_values.nil?
            if option.kind_of?(Array)
              x.each do |value|
                check_valid_value(option.valid_values, value)
              end
            else
              check_valid_value(option.valid_values, x)
            end
          end
          @parsed_args[option.symbol] = x
        end
      end
    end
  end

  def check_valid_value(valid_values, value)
    unless valid_values.include?(value.upcase)
      raise "Invalid value '#{value}'. Valid values are: '#{valid_values.inspect}'"
    end
  end

  def parse(args)
    @opt_parser.parse!(args)

    @options.each do |option|
      if !@parsed_args.include? option.symbol
        @parsed_args[option.symbol] = option.default_value
      end

      if option.required and @parsed_args[option.symbol].nil?
        raise "You need to set '#{option.long_alias}', it is a required field. Set it by passing "\
              "'--#{option.long_alias} #{option.long_alias.upcase}' as a command line argument or giving the "\
              "corresponding option a default value."
      end
    end

    return @parsed_args
  end
end