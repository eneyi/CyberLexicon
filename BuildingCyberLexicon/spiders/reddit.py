# -*- coding: utf-8 -*-
from scrapy import Spider
from scrapy.http import Request
from Krypton.items import KryptItem
from random import seed
seed(1000)

class RedditSpider(Spider):

    def getSubreddits(path='../inputfiles/subreddits.txt'):
        base = 'http://old.reddit.com/'
        with open(path, "r+") as ff:
            subreddits = [base+i.strip() for i in ff.readlines()]
        ff.close()
        return subreddits

    name = 'reddit'
    allowed_domains = ['old.reddit.com']
    start_urls = getSubreddits()
    custom_settings  = {"FEED_FORMAT":"json", "FEED_URI":"../outputfiles/reddit.json",}

    def parse(self, response):
        links = response.xpath("//a/@href").extract()
        commentsLinks = [i for i in links if 'comments' in i]
        commentsLinks=list(set(commentsLinks))

        for commentLink in commentsLinks:
            yield Request(response.urljoin(commentLink), callback=self.parse_comment_page)

        next_page = response.xpath("//span[@class='next-button']/a[@rel='nofollow next']/@href").extract_first()
        if next_page:
            yield Request(next_page, callback=self.parse)

    def parse_comment_page(self, response):
        #comments = response.xpath("//div[contains(@class, 'thing') and contains(@id ,'thing')]/div[@class='md']/p/text()").extract()
        comments = response.xpath("//form[contains(@class, 'usertext')]/div[contains(@class, 'usertext-body')]/div[@class='md']/p/text()").extract()
        for comment in comments:
            item = KryptItem(text=comment)
            yield item
