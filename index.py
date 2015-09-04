import tornado.ioloop
import tornado.web
import tornado.auth
from tornado import gen
import os
import json
import redis
import csv
from random import sample
from random import shuffle
# Link to the parser_ua library: https://github.com/selwin/python-user-agents
# install using: pip install pyyaml ua-parser user-agents
from user_agents import parse
import cv2
import numpy 
import base64
import matlab_wrapper
matlab = matlab_wrapper.MatlabSession(matlab_root="/Applications/MATLAB_R2015a.app")

import rpy2.robjects as ro
ro.r.load('./rf_predict.RData')
predict_on_pc = ro.r('predict_pc')
predict_on_mobile = ro.r('predict_mobile')


splits_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public/splits/")
splitsbk_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public/splits.bk/")


## image name, features, predicted class, score
## pick images that are under 10% and above 90%
image_list_low_pc = []
image_list_high_pc = []
with open("pc_test_cases.csv", "rb") as fd:
    reader = csv.reader(fd, delimiter=",")
    for row in reader:
        img_name = row[1]
        if img_name.find("_") > -1:
            threshold = int(img_name.split("_")[1].split(".")[0])
            if threshold <= 10:
                image_list_low_pc.append(row)
            elif threshold >= 90:
                image_list_high_pc.append(row)
        else:
            image_list_high_pc.append(row)

## repeat for mobile data
image_list_low_mobile = []
image_list_high_mobile = []
with open("mobile_test_cases.csv", "rb") as fd:
    reader = csv.reader(fd, delimiter=",")
    for row in reader:
        img_name = row[1]
        if img_name.find("_") > -1:
            threshold = int(img_name.split("_")[1].split(".")[0])
            if threshold <= 10:
                image_list_low_mobile.append(row)
            elif threshold >= 90:
                image_list_high_mobile.append(row)
        else:
            image_list_high_mobile.append(row)


class Index(tornado.web.RequestHandler):
    @tornado.web.asynchronous
    @tornado.gen.coroutine

    def get(self):
        name_list = []
        prob_list = []
        certainty_list = []
        prediction_list = []
        label_list = []
        ua_string = self.request.headers["User-Agent"]
        ua = parse(ua_string)
        if ua.is_mobile:
            image_list_low = image_list_low_mobile
            image_list_high = image_list_high_mobile
        else:
            image_list_low = image_list_low_pc
            image_list_high = image_list_high_pc
        bad_samples = sample(image_list_low, 4)
        good_samples = sample(image_list_high, 5)
        samples = good_samples + bad_samples
        shuffle(samples)
        for row in samples:
            prediction = row[12]
            prob_good = float(row[13])
            # certainty = 'sure' if (prob_good < 0.024 or prob_good > 0.98) else 'unsure'
            image_name = row[1]
            image_name = os.path.join(splits_path, image_name)
            label = row[14]
            ######  Code for predicting on the fly #######
            # image = cv2.imread(image_name, 0)
            # matlab.eval('clear')
            # matlab.eval('cd features_compute/')
            # matlab.put('im', image)
            # matlab.eval('divine_feature_extract')
            # x_diiv = matlab.get('x_diiv')

            # matlab.eval('brisque_feature')
            # x_bris = matlab.get('x_bris')
            # matlab.eval('cd ../')
            # matlab.eval('clear')
            # testQ = numpy.concatenate([x_diiv, [x_bris]]).tolist()
            # testQ = map(lambda i: round(i,4), testQ)
            # [is_good, prob_good] = predict_on_pc(testQ)
            # prediction = 'good' if is_good == 1 else 'bad'
            # #############################################
            name_list.append(image_name)
            prob_list.append(prob_good)
            # certainty_list.append(certainty)
            prediction_list.append(prediction)
            label_list.append(label)
        self.render("index.html", name_list=name_list, prob_list=prob_list, prediction_list=prediction_list, label_list=label_list)
        # self.render("index.html", name_list=name_list, prob_list=prob_list, certainty_list=certainty_list, prediction_list=prediction_list, label_list=label_list)

    def post(self):
        num_pics = int(self.get_argument('num_uploaded_pics'))
        pics_uid = self.get_argument('pics_uid').split(" ")    
        pics_uid = map(int, pics_uid)
        res_str_list = {}
        res_prob_list = {}
        res_cert_list = {}
        img_src_list = {}

        for i in pics_uid:
            img_string = self.get_argument('image_data_' + str(i)).split(",")[1]
            img_src_str = self.get_argument('image_data_' + str(i))
            img_src_list[i] = img_src_str
            img_tmp = base64.decodestring(img_string)
            img_buf = numpy.frombuffer(img_tmp, dtype=numpy.uint8)
            image = cv2.imdecode(img_buf, 0)
            matlab.eval('clear')    
            matlab.eval('cd ./features_compute/') 
            matlab.put('im', image)         
            # ua_string = self.request.headers["User-Agent"]
            # ua = parse(ua_string)
            # if ua.is_mobile:                            
            #     matlab.eval('feature_compute_fast_mobile')
            #     x_mobile = matlab.get('x_mobile')
            #     testQ = x_mobile.tolist()            
            #     testQ = map(lambda i: round(i,4), testQ)            
            #     [is_good, prob_good] = predict_on_mobile(testQ)
            # else:                
            
            matlab.eval('feature_compute_fast_pc')
            x_pc = matlab.get('x_pc')
            testQ = x_pc.tolist()
            testQ = map(lambda i: round(i,4), testQ)            
            [is_good, prob_good] = predict_on_pc(testQ)

            matlab.eval('cd ../')
            matlab.eval('clear')
            is_good_str = 'good' if is_good == 1 else 'bad'
            res_str_list[i] = is_good_str
            res_prob_list[i] = prob_good
            res_cert_list[i] = 'sure' if (prob_good < 0.024 or prob_good > 0.98) else 'unsure' 
        self.render("upload.html", uid_list=pics_uid, img_src_list=img_src_list, prob_list=res_prob_list, certainty_list=res_cert_list,prediction_list=res_str_list)
            

handlers = [
    (r'/(favicon.ico)', tornado.web.StaticFileHandler, {"path": ""}),            
    (r"/splits/(.*)", tornado.web.StaticFileHandler,
     {'path': splits_path}),
    (r"/splits.bk/(.*)", tornado.web.StaticFileHandler,
     {'path': splitsbk_path}),
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
