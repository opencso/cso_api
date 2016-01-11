from bs4 import BeautifulSoup
from urllib2 import urlopen
import re
import requests
import codecs


base = "http://www.cso.ie/StatbankServices/StatbankServices.svc/jsonservice/responseinstance/"
## this start page is a saved copy of
## http://www.cso.ie/webserviceclient/DatasetListing.aspx
## with all + menus open
## I know thats a crap scraper but I did it last year in a hurry
## and it works
start = "start.html"


def base_page(start):
    soup = BeautifulSoup(start, 'lxml')
    link = []
    for i in range(4, 200):
        tag = "itemTextLink" + str(i)
        current = soup.find(id=tag)
        if current is not None:
            href = current['href']
            if re.match("^http://www.cso.ie/webserviceclient", href):
                link.append(href)
            
    return link




def get_cso_links(link_file):
    all_links = []
    with open(link_file, 'r') as links:
        for line in links:
            all_links.append(line)


    for i, link in enumerate(all_links):
        r = requests.get(link)
        soup = BeautifulSoup(r.text, 'lxml')
        current = soup.find("table", { "class" : 'main'})
        hrefs = current.find_all("a")
        jsons = [] 
        for line in hrefs:
            ##print line['href']
            ##http://www.cso.ie/StatbankServices/StatbankServices.svc/jsonservice/responseinstance/CD406
            ##http://www.cso.ie/StatbankServices/StatbankServices.svc/jsonservice/responseinstance/SIA16
            if re.match("http://www.cso.ie/StatbankServices/StatbankServices.svc", line['href']):
                print line['href']
                jsons.append(line['href'])

        with open("linktojson", 'a') as linktojson:
            for line in jsons:
                linktojson.write(line + "\n")




def download_files():
    files = []
    path = "/home/dave/old_drive/apps/stat-maps/scraper/files/"
    with open("linktojson", "r") as open_file:
        for line in open_file:
            line=line.strip()
            r = requests.get(line)
            file_name = line[-5:]
            print file_name
        
            with codecs.open(path +file_name, "w", "utf-8") as writer:
                json_file = r.text
                #json_file = u"" + json_file.encode('utf-8').strip()
                writer.write(json_file)


##save all the base pages 
with open(start, "r") as html:
    base_links = base_page(html)
with open("links", "w") as writer:
    for line in base_links:
        writer.write(line + "\n")

## make a list of all the json containing links on base pages
get_cso_links("links")
## download the files
download_files()
