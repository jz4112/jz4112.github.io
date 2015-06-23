##
## The app is used to collect data for smart vision 
## Users are asked to pick a quality threshold at which 
## they cannot perceive a quality degradation
## so that any percentages beyond the threshold 
## are considered as good as the original and percentages below are worse
##
import tornado.ioloop
import tornado.web
import tornado.auth
from tornado import gen
import os
import json


class Index(tornado.web.RequestHandler):
    @tornado.web.asynchronous
    @tornado.gen.coroutine

    def get(self):
        self.render("index.html")


handlers = [
    (r'/(favicon.ico)', tornado.web.StaticFileHandler, {"path": ""}),            
    (r"/public/css/(.*)", tornado.web.StaticFileHandler,
     {'path': os.path.join(os.path.dirname(os.path.abspath(__file__)), "public/css/")}),
    ("/", Index)
]

settings = dict(
    template_path=os.path.join(os.path.dirname(__file__), "html_templates"),
    static_path=os.path.join(os.path.dirname(__file__), "public/"),
    debug=True
)

application = tornado.web.Application(handlers, **settings)

if __name__ == "__main__":
    application.listen(3000)
    tornado.ioloop.IOLoop.instance().start()
