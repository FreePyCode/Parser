require 'nokogiri'
require 'curb'
require 'csv'

ARG_URL = ARGV[0]
CSV_PATH = ARGV[1]
CSV_W = ARGV[2]
if CSV_W == "y" or CSV_W == "Y"
  CSV.open(CSV_PATH,'w', :write_headers=> true, :headers => %w(Name Price Image))
end

def product_parse (url, file_name )
  file_name.gsub!(/[\/!@%&"]/,'')
  file_path = "./pages/"
  ext = ".html"
  full_name = file_path + file_name + ext
  Curl::Easy.download(url, full_name)
  doc = Nokogiri::HTML(open( full_name))

  main_name = doc.xpath("//*[@class='product_main_name']")[0].text
  img_src = doc.xpath("//*[@id='bigpic']")[0]["src"]
  costs = doc.xpath("//*[@class='price_comb']").map do |cost|
    /\d+[.,]\d+/.match(cost.text)
  end
  names = doc.xpath("//*[@class='radio_label']").map do |name|
    "#{main_name} - #{name.text}"
  end

  result = []
  names.each_index do |i|
      result.append [names[i], costs[i], img_src]
  end
  result
end

def page_parse(url, name)
  puts "Обработка страницы #{name}..."
  ext = ".html"
  name = "./pages/" + name
  name += ext
  Curl::Easy.download(url, name)
  main_doc = Nokogiri::HTML(open(name))
  contents = main_doc.xpath("//a[@class='product_img_link product-list-category-img']")
  result = []
  contents.each do |i|
    result.append product_parse(i["href"], i["title"])
  end
  result
end

def save_to_csv(data ,file_path)
  csv = CSV.open(file_path,'ab')
  data.each do |multiproduct|
    multiproduct.each do |product|
      csv << product
    end
  end
  puts "Данные сохранены"
end


def category_parse(url, csv_path = "output.csv", name = "CategoryPage", products = 25)
  file_path = "./pages"
  bf = file_path + name + ".html"
  Curl::Easy.download(url, bf)
  doc = Nokogiri::HTML(open(bf))
  product_count = /\d+/.match(doc.xpath("//*[@class='heading-counter']")[0]).to_s.to_i
  page_count = product_count % 25 == 0 ? product_count / products : product_count / products + 1
  puts "Всего продуктов: #{product_count}"
  puts "Всего страниц: #{page_count}"
  save_to_csv(page_parse(url, name),csv_path)
  (2..page_count).each do |i|
     save_to_csv(page_parse(url+"?p=#{i}", name + "#{i}"), csv_path)
  end
end

  category_parse(ARG_URL, CSV_PATH)
