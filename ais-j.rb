require 'yaml'
require 'fileutils'
require 'mechanize'

config = YAML.load_file("config.yml")
airport = nil
if ARGV.length > 0
  airport = ARGV[0].dup
  else
    puts 'specify airport!!!!!!'
    exit(1)
  end

airport.upcase!

login_url = 'https://aisjapan.mlit.go.jp/Login.do'
aip_url = 'https://aisjapan.mlit.go.jp/html/AIP/html/'
$agent = Mechanize.new
$agent.user_agent_alias = 'Windows Mozilla'
top_page = $agent.get('https://aisjapan.mlit.go.jp/Login.do')
login_form = top_page.forms[0]
login_form.userID = config['userid']
login_form.password = config['password']
$agent.submit(login_form)

aip_top = $agent.get(aip_url + 'DomesticAIP.do')

puts 'select effective'
aip_top.links.each_with_index do |link, index|
  puts "[#{index}] #{link.text}"
end
aip_index = STDIN.gets.to_i

FileUtils.mkdir(airport) unless FileTest.exist?(airport)

link_base = aip_top.links[aip_index].href.sub(/index.html/, '')
airport_page =  link_base + "JP-AD-2-#{airport}-en-JP.html?#AD-2.#{airport}"
$chart_baseurl = aip_url + link_base
charts = $agent.get(aip_url + airport_page)

puts "AIRPORT #{airport}"
charts.links.each do |chart|
  if chart.href =~ /.pdf/  then
    filename = airport + '/' + chart.text.gsub(/\//, ' ').gsub(/(.*\r\n|\n|\r|\s)|^(Figure-\d{1,})|^image|(.pdf)$/, '') + '.pdf'
    print filename + ' '
    File.open(filename, 'wb') do | file |
      file.puts($agent.get_file($chart_baseurl + chart.href))
    end
    puts 'done'
  end
end
puts 'finish!'
