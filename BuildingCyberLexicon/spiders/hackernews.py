# -*- coding: utf-8 -*-
from scrapy import Spider
from scrapy.http import Request
from Krypton.items import KryptItem
from time import sleep
from random import seed
seed(1000)

class HackernewsSpider(Spider):
    name = 'hackernews'
    allowed_domains = ['thehackernews.com']
    start_urls = ['http://thehackernews.com/']
    custom_settings  = {"FEED_FORMAT":"json", "FEED_URI":"../outputfiles/hackernews.json",}

    def parse(self, response):
        posts = response.xpath("//div[@class='body-post clear']")

        for post in posts:
            storylink = post.xpath(".//a[@class='story-link']/@href").extract_first()
            yield Request(url=storylink, callback=self.parse_storylink)

        next_page = response.xpath("//a[contains(text(), 'Next Page')]/@href").extract_first()
        if next_page:
            yield Request(url=next_page, callback=self.parse)
            sleep(5)

    def parse_storylink(self, response):
        texts = response.xpath("//div[@dir='ltr']/text()").extract()
        for text in texts:
            if text != "\n":
                item = KryptItem(text=text)
                yield item
