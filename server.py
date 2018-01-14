#!/usr/bin/env python
# -*- coding:utf-8 -*-
import socket
import select
import Queue
ip_port = ('127.0.0.1',8888)
sk = socket.socket()
sk.bind(ip_port)
sk.listen(5)
sk.setblocking(False)
inputs = [sk]
"""
output函数用于select第二个参数，这个参数和第一个rList不同。第一个参数是inputs队里句柄有变化了才感知
第二个参数是只要output队列里有内容就会感知。
"""
output = []
"""
message字典用于存放文件句柄和队列内容
"""
message = {}
#message = {
#'c1':队列，
#'c2':队列，[b,bb,bbb]
#}
while True:
    rList,wList,e = select.select(inputs, output, inputs, 1)
    # 文件描述符可读，rList，一，只有变化，感知
    # 文件描述符可写，wList，二，只有存在，感知
    for r in rList:
        #如果过rList的内容有变动就证明一个新的客户端请求连接进来了
        if r == sk:
            conn,address = r.accept()
            #conn就是获取的socket文件句柄
            inputs.append(conn)
            #将字典的value值设置为队列
            message[conn] = Queue.Queue()
        #如果rList句柄没变动，就说明客户端已经连接好。准备接收客户端发来的数据
        else:
            client_data = r.recv(1024)
            #如果客户端发来的内容不为空
            if client_data:
                # 将获取的数据追加进output列表，此时select就会感知到第二个参数有值了
                output.append(r)
                #将文件句柄对应的客户端内容写入队列
                message[r].put(client_data)
            else:
                #如果发过来的数据为空，则删除input队列里对应的客户端文件句柄。表示断开连接
                inputs.remove(r)
    #如果select第二个参数有值,那么output的句柄就会被赋值给wList
    for w in wList:
        # 去指定队列取数据
        try:
            #nowait()方法Queue队列获取内容的时候不在阻塞，但是如果队列里没有数据了就报错
            data = message[w].get_nowait()
            #将队列里抓取出来的数据发还给客户端
            w.sendall(data)
        except Queue.Empty:
            pass
        #发送完数据之后马上删除output列表里的值，不然会一直触发
        output.remove(w)
        #删除字典里对应的值。
        del message[w]
