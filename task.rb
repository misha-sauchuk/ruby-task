require 'nokogiri'
require 'open-uri'
require 'csv'

# get url from user
puts ("Please, enter the URL: ")
home_page = gets.chomp()
begin
  puts ('Opening home page')
  html = open(home_page)
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
  link = doc.xpath("//a[@class='product_img_link product-list-category-img']")

  link.each do |tag|
    # search for the general name of product
    link_of_product = tag[:href]
    product_name = tag[:title]
    puts ("Loading data from the a page of a #{product_name}")
    # go to the product page
    html_of_product = open(link_of_product)
    # парсим страницу с продуктом
    doc_of_product = Nokogiri::HTML(html_of_product)
    # search for the image
    image = doc_of_product.xpath("//img[@id='bigpic']").map { |pic| pic[:src] }.to_s
    # search for the weight and the price for each product
    tag_price = doc_of_product.xpath("//label[contains(@class,'label_comb_price')]")

    tag_price.each do |w|
      data = []
      temp_name = w.search('span.radio_label').text.strip
      price = w.search('span.price_comb').text.strip
      product_full_name = product_name + " " + temp_name
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
  # conver url to the string and search for the number of the next page
  page_string = link_pagination.to_s
  start_index_page = page_string.rindex('=').to_i + 1
  next_page = page_string[start_index_page..-2].to_i

  # if current page is the last go out from the cycle
  if next_page == 0
    puts ("Finish")
    break
  end

  # create a new home url for the next page
  url = "#{home_page}?p=#{next_page}"
  # load a new home page
  puts ("Loading the page #{next_page}")
  html = open(url)
  doc = Nokogiri::HTML(html)

end
