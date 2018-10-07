# -*- coding: utf-8 -*-
from scrapy import Spider
from scrapy.http import Request
from Krypton.items import KryptItem
from random import seed
seed(1000)


class CwnSpider(Spider):
    name = 'cwn'
    allowed_domains = ['cyberwarnews.info']
    start_urls = ['http://www.cyberwarnews.info/page/'+str(page)+"/" for page in range(1,80)]
    custom_settings  = {"FEED_FORMAT":"json", "FEED_URI":"../outputfiles/cwn.json",}

    def parse(self, response):
        links = response.xpath("//a[@class='post-card-content-link']/@href").extract()
        for link in links:
            yield Request('http://www.cyberwarnews.info'+link, callback=self.parse_article)

    def parse_article(self, response):
        texts = response.xpath("//p/text()").extract()
        for text in texts:
            item = KryptItem(text=text)
            yield item
