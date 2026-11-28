require "test_helper"
require "selenium-webdriver"

WebMock.disable!

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.register_driver :isolated_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new(
      args: %w[ --headless --window-size=1400,1400 --disable-search-engine-choice-screen ]
    )
    options.add_argument("--disable-gpu") if Gem.win_platform?
    driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)

    # A fresh browser profile clears state across all origins without Capybara's wildcard CDP call.
    def driver.reset!
      quit
    end

    driver
  end

  driven_by :isolated_chrome

  include SystemTestHelper
  include RichTextEditorHelper
end
