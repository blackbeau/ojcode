# -*- coding: utf-8 -*-
"""
Created on Wed Dec 20 17:30:40 2017
@author: KaiYang
"""
import copy


class PyLuaTblParser:
    """A parser class can parse lua table string and python dict each other

    Attributes:
        _indict(dict): internal represention of the data
        s(str): the copy of lua table string for parse
        at(int): show index in the s to parse
        ch(char): the char in string stream to parse

    Example:
        test_parser = PyLuaTblParser()
        test_str = '{array = {65,23,5,},
        dict = {mixed = {43,54.33,false,9,string = "value",},array = {3,6,4,},
        string = "value",},}'
        test_parser.load(test_str)
        test_dict = test_parser.dumpDict()
        test_parser.loadDict(test_dict)
    """
    def __init__(self):
        self._indict = {'islist': False, 'data': {}}

    def load(self, s):
        """Load Lua table string from s

        Args:
            s: The input string.

        """
        self.at = 1
        self.s = s
        self.ch = self.s[0]
        if self._gettoken()[1] is '{':
            self._indict = self._myparse()
        else:
            raise NameError('not dict')
        if self._indict is None:
            raise NameError('not dict')
        return self._indict

    def _myparse(self):
        """Parse the input Lua table string

        Returns:
            The Lua table internal represention(python dict)

        """
        re = {'islist': True, 'data': {}}
        inner_id = 1
        last_tk = None
        tk = self._gettoken()
        while tk:
            if tk[0] == 'token':
                if tk[1] == '{':
                    re['data'][inner_id] = self._myparse()
                    inner_id += 1
                    tk = self._gettoken()
                elif tk[1] == '}':
                    if last_tk:
                        re['data'][inner_id] = last_tk[1]
                        inner_id += 1
                    return re
                elif tk[1] == '[':
                    tk = self._gettoken()
                    last_tk = tk
                    tk = self._gettoken()
                    if tk[1] != ']':
                        raise NameError('parse ] error')
                    # todo assert
                    tk = self._gettoken()
                elif tk[1] == '=':
                    re['islist'] = False
                    tk = self._gettoken()
                    if tk[1] == '{':
                        re['data'][last_tk[1]] = self._myparse()
                        tk = self._gettoken()
                        last_tk = None
                        continue
                    # todo assert
                    re['data'][last_tk[1]] = tk[1]
                    last_tk = None
                    tk = self._gettoken()
                elif tk[1] == ',':
                    if last_tk == 'token':
                        raise NameError('last_tk None')
                    # todo assert
                    if last_tk is not None:
                        re['data'][inner_id] = last_tk[1]
                        inner_id += 1
                    last_tk = None
                    tk = self._gettoken()
            elif tk[0] != 'token':
                last_tk = tk
                tk = self._gettoken()

    def _gettoken(self):
        """Get next token

        Returns:
            The next token in string stream

        """
        re = ''
        if self.ch is not None:
            return None
        while True:
            flag = False
            while True:
                if self.ch not in [' ', '\n', '\t', '\r']:
                    break
                self._nextchar()
                flag = True
            if self.s[self.at-1:self.at+3] == '--[[':  # todo lencheck
                while self.s[self.at-1:self.at+1] != ']]':
                    self._nextchar()
                self._nextchar()
                self._nextchar()
                flag = True
            if self.s[self.at-1:self.at+1] == '--':
                while self.ch != '\n':  # todo lencheck
                    self._nextchar()
                self._nextchar()
                flag = True
            if flag is False:
                break
        if self.ch in ['{', '}', '[', ']', '=', ',']:
            re = self.ch
            self._nextchar()
            return ('token', re)
        if self.ch == '"':
            last = self.ch
            while self.ch:
                self._nextchar()
                if self.ch == '"' and last != '\\':
                    self._nextchar()
                    return ('string', self._decode(re))
                if self.ch == '"' and last == '\\':
                    # re=re[:-1]
                    pass
                if self.ch == '\\' and last == '\\':
                    # re=re[:-1]
                    re += self.ch
                    last = None
                    continue
                last = self.ch
                re += self.ch
            if self.ch is None:
                raise NameError('end string error')
        while self.ch:
            re += self.ch
            self._nextchar()
            if self.ch in [' ', '\n', '\t', '{', '}', '[', ']', '=', ',', '\r']:
                if re[0].isdigit() or re[0] == '-':
                    try:
                        return ('number', int(re, 0))
                    except:
                        pass
                    try:
                        return ('number', float(re))
                    except:
                        pass
                boolAndNone = {'true': True, 'false': False, 'nil': None}
                return ('t_string', boolAndNone.get(re, self._decode(re)))

    def _nextchar(self):
        """Move one char in string stream

        """
        if self.at < len(self.s):
            self.ch = self.s[self.at]
            self.at += 1
        else:
            self.ch = None

    def dump(self):
        """Dump a string which Lua can parse to the original table

        Returns:
            Dumped string

        """
        return self._mydump(self._indict)

    def _mydump(self, obj):
        """Internal method of self.dump()

        Returns:
            Dumped string

        """
        boolAndNone = {True: 'true', False: 'false', None: 'nil'}
        re = ''
        re += '{'
        for k in obj['data']:
            if obj['islist'] is False:
                if isinstance(k, (int, float)):
                    re += '['+str(k)+']='
                else:
                    re += '["'
                    re += str(k).encode('string_escape').replace('"', r'\"')
                    re += '"]='
            if type(obj['data'][k]) in (float, int):
                re += str(obj['data'][k])
            elif isinstance(obj['data'][k], dict):
                re += self._mydump(obj['data'][k])
            else:
                if obj['data'][k] in boolAndNone:
                    re += boolAndNone[obj['data'][k]]

                else:
                    re += '"'
                    re += str(obj['data'][k]).encode('string_escape').replace('"', r'\"')
                    re += '"'
            re += ','
        re += '}'
        return re

    def loadDict(self, d):
        """Read data from a dict and store by class

        Args:
            d: The input dict

        """
        if isinstance(d, (dict)):
            self._indict = self._myLoadDict(copy.deepcopy(d))
        else:
            raise NameError('not dict')

    def _myLoadDict(self, obj):
        """Internal method of self.loadDict()

        Args:
            d: The input dict

        """
        if not isinstance(obj, (dict, list)):
            return obj
        re = {'islist': True, 'data': {}}
        if isinstance(obj, (dict)):
            re['islist'] = False
            for k in obj:
                if type(k) in (str, float, int):
                    re['data'][k] = self._myLoadDict(obj[k])
        else:
            id = 1
            for k in obj:
                k = k
                re['data'][id] = self._myLoadDict(k)
                id += 1
        return re

    def dumpDict(self):
        """Return a dict represent the Lua table

        Returns:
            The Dict represent the Lua table

        """
        tempdict = copy.deepcopy(self._indict)
        return self._myDumpDict(tempdict)

    def _myDumpDict(self, obj):
        """Internal method of self.dumpDict()

        Returns:
            The Dict represent the Lua table

        """
        if not isinstance(obj, dict):
            return obj
        if obj['islist']:
            re = []
            for k in obj['data']:
                re.append(self._myDumpDict(obj['data'][k]))
        else:
            re = {}
            for k in obj['data']:
                if obj['data'][k] is not None:
                    re[k] = self._myDumpDict(obj['data'][k])
        return re

    def _decode(self, s):
        """Erase the redundant Escape character in a string

        Args:
            s: The input string

        Returns:
            string wihtout redundant Escape character

        """
        if not isinstance(s, str):
            return s
        k = s
        return k.decode('string_escape')

    def loadLuaTable(self, f):
        """Same as the method self.load(),just read from file

        Args:
            f: The Filename

        """
        with open(f) as fi:
            self.load(fi.read())

    def dumpLuaTable(self, f):
        """Same as the method self.dump(),just dump to file

        Args:
            f: The Filename

        """
        with open(f, 'w') as fi:
            fi.write(self.dump())
