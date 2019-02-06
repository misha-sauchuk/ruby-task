require 'nokogiri'
require 'csv'
require 'curb'

# get url from user
puts ("Please, enter the URL: ")
home_page = gets.chomp()
begin
  puts ('Opening home page')
  html = Curl.get(home_page).body_str
rescue
  puts ("Your URL is incorect")
end

# create output file
puts ("Please, enter file name (e.g.: file.csv): ")
file = gets.chomp()
CSV.open(file,"w") do |file|
  file << ["Name", "Price", "Image"]
end

puts ("Loading home page")
doc = Nokogiri::HTML(html)

while TRUE
  # search for the link of the each products
  puts ("Searching for all products URL on the current page")
  link = doc.xpath("//a[@class='product_img_link product-list-category-img']")
  links = []
  # put each link on the current page to the array
  link.each do |tag|
    # search for the general name of product
    link_of_product = tag[:href]
    links << link_of_product
  end
  # load all the products pages simultaneously
  puts ("Start to collect data of all products on the curent page")
  Curl::Multi.get(links, :follow_location => true) do|easy|
    doct = easy.body_str
    # parsing each product page
    doc_of_product = Nokogiri::HTML(doct)
    # search for the product name
    product_name = doc_of_product.xpath("//span[@class='navigation_page']").text.strip
    # search for the image
    image = doc_of_product.xpath("//img[@id='bigpic']").map { |pic| pic[:src] }.to_s
    # search for the weight and the price for each product
    tag_price = doc_of_product.xpath("//label[contains(@class,'label_comb_price')]")
    tag_price.each do |w|
      data = []
      temp_name = w.search('span.radio_label').text.strip
      price = w.search('span.price_comb').text.strip
      product_full_name = product_name + " - " + temp_name
      # create an Array with full name, price and image of product
      data = [
        product_full_name,
        price,
        image[2..-3]
      ]
      # add a new data to the output file
      CSV.open(file,"a") do |file|
        file << data
      end
    end
  end

  # search for the next home page
  link_pagination = doc.xpath("//li[@class='pagination_next']/a").map { |url| url[:href] }
  # convert url to the string and search for the number of the next page
  page_string = link_pagination.to_s
  start_index_page = page_string.rindex('=').to_i + 1
  next_page = page_string[start_index_page..-2].to_i

  # if current page is the last go out from the cyrcle
  if next_page == 0
    puts ("Finish")
    break
  end

  # create a new home url for the next page
  url = "#{home_page}?p=#{next_page}"
  # load next page
  puts ("Loading the page #{next_page}")
  html = Curl.get(url).body_str
  doc = Nokogiri::HTML(html)

end
