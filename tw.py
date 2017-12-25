# -*- coding: utf-8 -*-
"""
Created on Mon Dec 25 15:16:09 2017

@author: KaiYang
"""

# -*- coding: utf-8 -*-
"""
Created on Wed Dec 20 17:30:40 2017

@author: KaiYang
"""

class PyLuaTblParser:
    def __init__(self):
        self._indict={}
    def load(self, s):
        self.at = 1
        self.s = s
        self.ch = self.s[0]
        if self._gettoken()[1] is '{':
            self._indict=self._myparse()
        else:
            raise NameError('not dict')
        return self._indict
    def _myparse(self):
        re = {'islist':True,'data':{}}
        inner_id=1
        last_tk=None
        tk=self._gettoken()
        while tk:
            print tk,self.at,self.ch,last_tk
            if tk[0] == 'token':
                if tk[1] == '{':
                    re['data'][inner_id]=self._myparse()
                    inner_id += 1
                    tk=self._gettoken()
                elif tk[1]=='}':
                    if last_tk:
                        re['data'][inner_id] = last_tk
                        inner_id += 1
                    # tk=self._gettoken()
                    return re
                elif tk[1] == '[':
                    tk=self._gettoken()
                    last_tk = tk[1]
                    tk=self._gettoken()
                    if tk[1] != ']':
                        print self.at
                        raise NameError('parse ] error')
                    #todo assert
                    tk=self._gettoken()
                elif tk[1] == '=':
                    re['islist']=False
                    tk=self._gettoken()
                    if tk[1] == '{':
                        re['data'][last_tk] = self._myparse()
                        tk=self._gettoken()
                        last_tk = None
                        continue
                    #todo assert
                    re['data'][last_tk] = tk[1]
                    last_tk = None
                    tk=self._gettoken()
                elif tk[1] == ',':
                    if last_tk == 'token':
                        raise NameError('last_tk None')
                    #todo assert
                    if last_tk != None:
                        re['data'][inner_id] = last_tk
                        inner_id += 1
                    last_tk = None
                    tk=self._gettoken()
            elif tk[0] != 'token':
                last_tk = tk[1]
                tk=self._gettoken()
    def _gettoken(self):
        re=''
        if self.ch == None:
            return None
        while True:
            flag = False
            while True:
                if self.ch not in [' ','\n','\t']:
                    break
                self._nextchar()
                flag = True
            if self.s[self.at-1:self.at+3] =='--[[':#todo lencheck
                while self.s[self.at-1:self.at+1] != ']]':
                    self._nextchar()
                self._nextchar()
                self._nextchar()
                flag = True
            if self.s[self.at-1:self.at+1] =='--':
                while self.ch != '\n':#todo lencheck
                    self._nextchar()
                self._nextchar()
                flag = True
            if flag == False:
                break
        if self.ch in ['{','}','[',']','=',',']:
            re=self.ch
            self._nextchar()
            return ('token',re)
        if self.ch == '"':
            last = self.ch
            while self.ch:
                self._nextchar()
                if self.ch == '"' and last != '\\':
                    self._nextchar()
                    return ('string',re)
                if self.ch == '"' and last == '\\':
                    re=re[:-1]
                last = self.ch
                re+=self.ch
            if self.ch is None:
                raise NameError('end string error')
        while self.ch:
            re+=self.ch
            self._nextchar()
            if self.ch in [' ','\n','\t','{','}','[',']','=',',']:
                return ('t_string',re)

    def _nextchar(self):
        if self.at < len(self.s):
            self.ch = self.s[self.at]
            self.at += 1
        else :
            self.ch = None
test_str = '{\nroot = {\n\t"Test Pattern String",\n\t-- {"object with 1 member" = {"array with 1 element",},},\n\t{["object wh 1 member"] = {"array with 1 element",},},\n\t{},\n\t[99] = -42,\n\t[98] = {{}},\n\t[97] = {{},{}},\n\t[96] = {{}, 1, 2, nil},\n\t[95] = {1, 2, {["1"] = 1}},\n\t[94] = { {["1"]=1, ["2"]=2}, {1, ["2"]=2}, ["3"] = 3 },\n\ttrue,\n\tfalse,\n\tnil,\n\t{\n\t\t["integer"]= 1234567890,\n\t\treal=-9876.543210,\n\t\te= 0.123456789e-12,\n\t\tE= 1.234567890E+34,\n\t\tzero = 0,\n\t\tone = 1,\n\t\tspace = " ",\n\t\tquote = "\\"",\n\t\tbackslash = "\\\\",\n\t\tcontrols = "\\b\\f\\n\\r\\t",\n\t\tslash = "/ & \\\\",\n\t\talpha= "abcdefghijklmnopqrstuvwyz",\n\t\tALPHA = "ABCDEFGHIJKLMNOPQRSTUVWYZ",\n\t\tdigit = "0123456789",\n\t\tspecial = "`1~!@#$%^&*()_+-={\':[,]}|;.</>?",\n\t\thex = "0x01230x45670x89AB0xCDEF0xabcd0xef4A",\n\t\t["true"] = true,\n\t\t["false"] = false,\n\t\t["nil"] = nil,\n\t\tarray = {nil, nil,},\n\t\tobject = {  },\n\t\taddress = "50 St. James Street",\n\t\turl = "http://www.JSON.org/",\n\t\tcomment = "// /* <!-- --",\n\t\t["# -- --> */"] = " ",\n\t\t[" s p a c e d " ] = {1,2 , 3\n\n\t\t\t,\n\n\t\t\t4 , 5        ,          6           ,7        },\n\t\t--[[[][][]  Test multi-line comments\n\t\t\tcompact = {1,2,3,4,5,6,7},\n\t- -[luatext = "{\\"object with 1 member\\" = {\\"array with 1 element\\"}}",\n\t\tquotes = "&#34; (0x0022) %22 0x22 034 &#x22;",\n\t\t["\\\\\\"\\b\\f\\n\\r\\t`1~!@#$%^&*()_+-=[]{}|;:\',./<>?"]\n\t\t= "A key can be any string"]]\n\t--         ]]\n\t\tcompact = {1,2,3,4,5,6,7},\n\t\tluatext = "{\\"object with 1 member\\" = {\\"array with 1 element\\"}}",\n\t\tquotes = "&#34; (0x0022) %22 0x22 034 &#x22;",\n\t\t["\\\\\\"\\b\\f\\n\\r\\t`1~!@#$%^&*()_+-=[]{}|;:\',./<>?"]\n\t\t= "A key can be any string"\n\t},\n\t0.5 ,31415926535897932384626433832795028841971693993751058209749445923.\n\t,\n\t3.1415926535897932384626433832795028841971693993751058209749445923\n\t,\n\n\t1066\n\n\n\t,"rosebud"\n\n}}'
#test_str=
"""--[[[][][]  Test multi-line comments
			compact = {1,2,3,4,5,6,7},
	- -[luatext = "{\"object with 1 member\" = {\"array with 1 element\"}}",
		quotes = "&#34; (0x0022) %22 0x22 034 &#x22;",
		["\\\"\b\f\n\r\t`1~!@#$%^&*()_+-=[]{}|;:',./<>?"]
		= "A key can be any string"]]
	--         ]]
		{compact = {1,2,3,4,5,6,7}}"""
myp=PyLuaTblParser()
data=myp.load(test_str)
