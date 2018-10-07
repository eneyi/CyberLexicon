# -*- coding: utf-8 -*-
from scrapy import Spider
from scrapy.http import Request
from time import sleep
from  Krypton.items import KryptItem
from random import seed
seed(1000)


class StackspiderSpider(Spider):
    name = 'stackspider'
    allowed_domains = ['stackoverflow.com']
    start_urls = ['https://stackoverflow.com/questions?sort=votes']

    custom_settings  = {"FEED_FORMAT":"json", "FEED_URI":"../outputfiles/stackoverflow.json", "DOWNLOAD_DELAY":10}

    def parse(self, response):
        links = response.xpath("//div[@class='summary']/h3/a/@href").extract()
        current_page = response.xpath("//span[@class='page-numbers current']/text()").extract_first()

        for link in links:
            yield Request(response.urljoin(link), callback=self.parse_question)


        #get only first 60 pages
        if int(current_page) < 61:
            next_page = response.xpath("//a[@rel='next']/@href").extract_first()
            yield Request(response.urljoin(next_page), callback=self.parse)


    def parse_question(self, response):
        post_texts = response.xpath("//div[@class='post-text']/p/text()").extract()
        comments = response.xpath("//span[@class='comment-copy']/text()").extract()
        texts = post_texts+comments
        for text in texts:
            item = KryptItem(text=text)
            yield item
