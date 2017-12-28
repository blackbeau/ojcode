# -*- coding: utf-8 -*-
"""
Created on Wed Dec 20 17:30:40 2017
@author: KaiYang
"""
import copy
class PyLuaTblParser:
    def __init__(self):
        self._indict= {'islist':False,'data':{}}
    def load(self, s):
        self.at = 1
        self.s = s
        self.ch = self.s[0]
        if self._gettoken()[1] is '{':
            self._indict=self._myparse()
        else:
            raise NameError('not dict')
        if self._indict is None:
            raise NameError('not dict')
        return self._indict
    def _myparse(self):
        re = {'islist':True,'data':{}}
        inner_id=1
        last_tk=None
        tk=self._gettoken()
        while tk:
            #print tk,self.at,self.ch,last_tk
            if tk[0] == 'token':
                if tk[1] == '{':
                    re['data'][inner_id]=self._myparse()
                    #if re['data'][inner_id] != None:
                    inner_id += 1
                    tk=self._gettoken()
                elif tk[1]=='}':
                    if last_tk:
                        #if last_tk[1] != None:
                        re['data'][inner_id] = last_tk[1]
                        #re['data'][inner_id] != None:
                        inner_id += 1
                    # tk=self._gettoken()
                    return re
                elif tk[1] == '[':
                    tk=self._gettoken()
                    last_tk = tk
                    tk=self._gettoken()
                    if tk[1] != ']':
                        #print self.at
                        raise NameError('parse ] error')
                    #todo assert
                    tk=self._gettoken()
                elif tk[1] == '=':
                    re['islist']=False
                    tk=self._gettoken()
                    if tk[1] == '{':
                        re['data'][last_tk[1]] = self._myparse()
                        tk=self._gettoken()
                        last_tk = None
                        continue
                    #todo assert
                    re['data'][last_tk[1]] = tk[1]
                    last_tk = None
                    tk=self._gettoken()
                elif tk[1] == ',':
                    if last_tk == 'token':
                        raise NameError('last_tk None')
                    #todo assert
                    if last_tk != None:
                        #if last_tk[1] != None:
                        re['data'][inner_id] = last_tk[1]
                        #if re['data'][inner_id] != None:
                        inner_id += 1
                    last_tk = None
                    tk=self._gettoken()
            elif tk[0] != 'token':
                last_tk = tk
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
                    #re=re[:-1]
                    pass
                if self.ch == '\\' and last == '\\':
                    #re=re[:-1]
                    re+=self.ch
                    last=None
                    continue
                last = self.ch
                re+=self.ch
            if self.ch is None:
                raise NameError('end string error')
        while self.ch:
            re+=self.ch
            self._nextchar()
            if self.ch in [' ','\n','\t','{','}','[',']','=',',']:
                if re[0].isdigit() or re[0] == '-':
                    try:
                        return ('number',int(re, 0))
                    except:
                        pass
                    try:
                        return ('number',float(re))
                    except:
                        pass
                boolAndNone = {'true': True, 'false': False, 'nil': None}
                return ('t_string',boolAndNone.get(re,re))

    def _nextchar(self):
        if self.at < len(self.s):
            self.ch = self.s[self.at]
            self.at += 1
        else :
            self.ch = None
    def dump(self):
        return self._mydump(self._indict)
    def _mydump(self,obj):
        boolAndNone = {True: 'true', False: 'false', None: 'nil'}
        re=''
        re+='{'
        for k in obj['data']:
            if obj['islist'] == False:
                #print obj['islist'] ,type(obj['data'][k])
                if isinstance(k,(int,float)):
                    re+='['+str(k)+']='
                else:
                    re+='["'+str(k)+'"]='
            if type(obj['data'][k]) in (float,int):
                #print obj['data'][k],type(obj['data'][k])
                re+=str(obj['data'][k])
            elif isinstance(obj['data'][k],dict):
                re+=self._mydump(obj['data'][k])
            else:
                if obj['data'][k] in boolAndNone:
                    #print boolAndNone[obj['data'][k]]
                    re+=boolAndNone[obj['data'][k]]
                    
                else:   
                    #print obj['data'][k],type(obj['data'][k])
                    re+='"'+str(obj['data'][k])+'"'
            re+=','
        re+='}'
        return re
    def loadDict(self,d):
        #d={'root': {96: [[], 1, 2, None], 97: [[], []], 98: [[]], 99: -42, 4: True, 5: False, 1: 'Test Pattern String', 8: 0.5, 9: 3.141592653589793e+64, 10: 3.141592653589793, 7: {'comment': '// /* <!-- --', 'slash': '/ & \\', 'luatext': '{"object with 1 member" = {"array with 1 element"}}', 'hex': '0x01230x45670x89AB0xCDEF0xabcd0xef4A', 'object': [], '\\"\x08\x0c\n\r\t`1~!@#$%^&*()_+-=[]{}|;:\',./<>?': 'A key can be any string', 'integer': 1234567890, 'space': ' ', 'controls': '\x08\x0c\n\r\t', 'quote': '"', 'alpha': 'abcdefghijklmnopqrstuvwyz', 'E': 1.23456789e+34, ' s p a c e d ': [1, 2, 3, 4, 5, 6, 7], 'compact': [1, 2, 3, 4, 5, 6, 7], 'one': 1, 'array': [None, None], '# -- --> */': ' ', 'ALPHA': 'ABCDEFGHIJKLMNOPQRSTUVWYZ', 'e': 1.23456789e-13, 'digit': '0123456789', 'false': False, 'url': 'http://www.JSON.org/', 'backslash': '\\', 'special': "`1~!@#$%^&*()_+-={':[,]}|;.</>?", 'real': -9876.54321, 'true': True, 'quotes': '&#34; (0x0022) %22 0x22 034 &#x22;', 'address': '50 St. James Street', 'zero': 0}, 12: 'rosebud', 2: {'object with 1 member': ['array with 1 element']}, 11: 1066, 3: [], 94: {'3': 3, 1: {'1': 1, '2': 2}, 2: {'2': 2, 1: 1}}, 95: [1, 2, {'1': 1}]}}
        if isinstance(d,(dict)):
            self._indict=self._myLoadDict(copy.deepcopy(d))
        else:
            raise NameError('not dict')
    def _myLoadDict(self,obj):
        if not isinstance(obj,(dict,list)):
            return obj
        re = {'islist':True,'data':{}}
        if isinstance(obj,(dict)):
            re['islist']=False
            for k in obj:
                if type(k) in (str,float,int):
                    re['data'][k]=self._myLoadDict(obj[k])
        else:
            id=1
            for k in obj:
                if type(k) in (str,float,int):
                    re['data'][id]=self._myLoadDict(k)
                    id+=1
        return re
    def dumpDict(self):
        tempdict=copy.deepcopy(self._indict)
        return self._myDumpDict(tempdict)
    def _myDumpDict(self,obj):
        if not isinstance(obj,dict):
            return obj
        if obj['islist']:
            re=[]
            for k in obj['data']:
                re.append(self._myDumpDict(obj['data'][k]))
        else:
            re={}
            for k in obj['data']:
                if obj['data'][k] != None:
                    re[k]=self._myDumpDict(obj['data'][k])
        return re        
                  
    def loadLuaTable(self,f):
        with open(f) as fi:
             self.load(fi.read())
    def dumpLuaTable(self, f):
#        if os.path.exists(f):
#            raise NameError('file exist')
        with open(f, 'w') as fi:
            fi.write(self.dump())
