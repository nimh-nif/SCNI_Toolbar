import json
import time
import sys
import re
try:
    import httplib as http # python 2.x
except ImportError:
    import http.client as http # python 3.x

class SynapseAPI:
    Modes = ('Idle', 'Standby', 'Preview', 'Record') #, 'Unknown'

    def __init__(self, server = "localhost", port = 24414):
        self.synCon = http.HTTPConnection(server, port)
        self.lastReqStr = ''
        self.reSueTank = re.compile('subject|user|experiment|tank|block')
        self.demoExperiments = ['demoAudioStim1','demoUser1','demoPCSort','demoBoxSort','demoTetSort','demoChanMap','demoSigSelector','demoSigInjector','demoElecStim','demoFileStim','demoParSeq']
        self.demoRequiredGizmos = {'demoAudioStim1':'aStim1','demoUser1':'TagTest1','demoPCSort':'Neu1','demoBoxSort':'Box1','demoTetSort':'Tet1','demoChanMap':'Map1','demoSigSelector':'Sel1','demoSigInjector':'Inj1','demoElecStim':'eStim1','demoFileStim':'fStim1','demoParSeq':'ParSeq1'}

    def __del__(self):
        self.synCon.close()

    def connect(self):
        self.synCon.close()
        try:
            self.synCon.connect()
        except Exception as e:
            raise Exception('failed to connect to Synapse\n' + str(e))

    def exceptMsg(self):
        retval = ''

        if 'params' in self.lastReqStr:
            retval = '\nSynapse may need to be in non-Idle mode'
        elif self.reSueTank.search(self.lastReqStr) is not None:
            retval = '\nSynapse may need to be in Idle mode'

        return retval

    def getResp(self):
        try:
            resp = self.synCon.getresponse()

            # success
            if resp.status == 200:
                retval = json.loads(resp.read().decode('utf-8'))
            # previous request sent was invalid, why?
            else:
                raise Exception('%s%s' % (resp.reason, self.exceptMsg()))

        except:
            # some HTTP exceptions are such that subsequent communications may fail if we don't re-establish
            self.connect()
            raise Exception('failed to retrieve response from Synapse' + self.exceptMsg())

        return retval

    def sendRequest(self, reqTypeStr, reqStr, reqData = None):
        '''
        reqTypeStr = HTTP methods, e.g. 'GET', 'PUT', 'OPTIONS'
        reqData = JSON formatted data
        '''

        try:
            if reqData is None:
                self.synCon.request(reqTypeStr, reqStr)
            else:
                self.synCon.request(reqTypeStr, reqStr, reqData, {'Content-type' : 'application/json'})

            self.lastReqStr = reqStr

        except:
            self.connect()
            raise Exception('failed to send %s %s to Synapse' % (reqTypeStr, reqStr))

    def sendGet(self, reqStr, respKey = None, reqData = None):
        self.sendRequest('GET', reqStr, reqData)
        resp = self.getResp()

        try:
            if respKey is None:
                retval = resp
            else:
                retval = resp[respKey]

        except:
            retval = None

        return retval

    def sendPut(self, reqStr, reqData):
        self.sendRequest('PUT', reqStr, reqData)
        # we must read and 'clear' response
        # otherwise subsequent HTTP request may fail
        self.getResp()

    def sendOptions(self, reqStr, respKey):
        self.sendRequest('OPTIONS', reqStr)

        try:
            retval = self.getResp()[respKey]
        except:
            retval = []

        return retval

    def parseJsonString(self, jsonData):
        try:
            retval = str(jsonData)
        except:
            retval = ''

        return retval

    def parseJsonStringList(self, jsonData):
        retval = []
        for value in jsonData:
            retval.append(self.parseJsonString(value))

        return retval

    def parseJsonFloat(self, jsonData, result = []):
        try:
            retval = float(jsonData)
        except:
            retval = 0.0
            # notify caller if interested
            if len(result) > 0:
                result[0] = False

        return retval

    def parseJsonFloatList(self, jsonData, result = []):
        retval = []
        for value in jsonData:
            retval.append(self.parseJsonFloat(value, result))

        return retval

    def parseJsonInt(self, jsonData):
        return int(self.parseJsonFloat(jsonData))

    def getMode(self):
        '''
        -1: Error
         0: Idle
         1: Standby
         2: Preview
         3: Record
        '''

        try:
            retval = self.Modes.index(self.sendGet('/system/mode', 'mode'))
        except:
            retval = -1

        return retval

    def getModeStr(self):
        '''
        '' (Error)
        'Idle'
        'Standby'
        'Preview'
        'Record'
        '''

        retval = self.getMode()
        if retval == -1:
            retval = ''
        else:
            retval = self.Modes[retval]

        return retval

    def setMode(self, mode):
        '''
        mode must be an integer between 0 and 3, inclusive
        '''

        if mode in range(len(self.Modes)):
            self.sendPut('/system/mode', json.dumps({'mode' : self.Modes[mode]}))
        else:
            raise Exception('invalid call to setMode()')

    def setModeStr(self, modeStr):
        '''
        string equivalent of setMode()
        '''

        try:
            mode = self.Modes.index(modeStr)
        except:
            raise Exception('invalid call to setModeStr()')

        self.setMode(mode)

    def issueTrigger(self, id):
        self.sendPut('/trigger/' + str(id), None)

    def getSystemStatus(self):
        retval = {'sysLoad' : 0, 'uiLoad' : 0, 'errorCount' : 0, 'rateMBps' : 0, 'recordSecs' : 0}
        resp = self.sendGet('/system/status')

        sysStat = {'sysLoad' : '', 'uiLoad' : '', 'errors' : '', 'dataRate' : '', 'recDur' : ''}
        for key in resp:
            try:
                sysStat[key] = resp[key]
            except:
                continue

        # Synapse internal keys : user friendly keys
        keyMap = {'sysLoad' : 'sysLoad', 'uiLoad' : 'uiLoad', 'errors' : 'errorCount', 'dataRate' : 'rateMBps', 'recDur' : 'recordSecs'}
        for key in sysStat:
            try:
                if key == 'dataRate':
                    # '0.00 MB/s'
                    retval[keyMap[key]] = float(sysStat[key].split()[0])
                elif key == 'recDur':
                    # 'HH:MM:SSs'
                    recDur = sysStat[key][:-1].split(':')
                    retval[keyMap[key]] = int(recDur[0]) * 3600 + int(recDur[1]) * 60 + int(recDur[2])
                else:
                    retval[keyMap[key]] = int(sysStat[key])

            except:
                continue

        return retval

    def getPersistModes(self):
        return self.parseJsonStringList(self.sendOptions('/system/persist', 'modes'))

    def getPersistMode(self):
        return self.parseJsonString(self.sendGet('/system/persist', 'mode'))

    def setPersistMode(self, modeStr):
        self.sendPut('/system/persist', json.dumps({'mode' : modeStr}))

    def getSamplingRates(self):
        retval = {}
        resp = self.sendGet('/processor/samprate')

        for proc in list(resp.keys()):
            retval[self.parseJsonString(proc)] = self.parseJsonFloat(resp[proc])

        return retval

    def getKnownSubjects(self):
        return self.parseJsonStringList(self.sendOptions('/subject/name', 'subjects'))

    def getKnownUsers(self):
        return self.parseJsonStringList(self.sendOptions('/user/name', 'users'))

    def getKnownExperiments(self):
        return self.parseJsonStringList(self.sendOptions('/experiment/name', 'experiments'))

    def getKnownTanks(self):
        return self.parseJsonStringList(self.sendOptions('/tank/name', 'tanks'))

    def getKnownBlocks(self):
        return self.parseJsonStringList(self.sendOptions('/block/name', 'blocks'))

    def getCurrentSubject(self):
        return self.parseJsonString(self.sendGet('/subject/name', 'subject'))

    def getCurrentUser(self):
        return self.parseJsonString(self.sendGet('/user/name', 'user'))

    def getCurrentExperiment(self):
        return self.parseJsonString(self.sendGet('/experiment/name', 'experiment'))

    def getCurrentTank(self):
        return self.parseJsonString(self.sendGet('/tank/name', 'tank'))

    def getCurrentBlock(self):
        return self.parseJsonString(self.sendGet('/block/name', 'block'))

    def setCurrentSubject(self, name):
        self.sendPut('/subject/name', json.dumps({'subject' : name}))

    def setCurrentUser(self, name, pwd = ''):
        self.sendPut('/user/name', json.dumps({'user' : name, 'pwd' : pwd}))

    def setCurrentExperiment(self, name):
        self.sendPut('/experiment/name', json.dumps({'experiment' : name}))

    def setCurrentTank(self, name):
        self.sendPut('/tank/name', json.dumps({'tank' : name}))

    def setCurrentBlock(self, name):
        self.sendPut('/block/name', json.dumps({'block' : name}))

    def createTank(self, path):
        self.sendPut('/tank/path', json.dumps({'tank' : path}))

    def createSubject(self, name, desc = '', icon = 'mouse'):
        self.sendPut('/subject/name/new', json.dumps({'subject' : name, 'desc' : desc, 'icon' : icon}))

    def getGizmoNames(self):
        return self.parseJsonStringList(self.sendOptions('/gizmos', 'gizmos'))

    def getParameterNames(self, gizmoName):
        return self.parseJsonStringList(self.sendOptions('/params/' + gizmoName, 'parameters'))

    def getParameterInfo(self, gizmoName, paramName):
        info = self.parseJsonStringList(self.sendGet('/params/info/%s.%s' % (gizmoName, paramName), 'info'))
        keys = ('Name', 'Unit', 'Min', 'Max', 'Access', 'Type', 'Array')

        retval = {}
        for i in range(len(keys)):
            key = keys[i]

            try:
                retval[key] = info[i]

                if key == 'Array' and info[i] != 'No' and info[i] != 'Yes':
                    retval[key] = int(info[i])
                elif key == 'Min' or key == 'Max':
                    retval[key] = float(info[i])

            except:
                retval[key] = None

        return retval

    def getParameterSize(self, gizmoName, paramName):
        return self.parseJsonInt(self.sendGet('/params/size/%s.%s' % (gizmoName, paramName), 'value'))

    def getParameterValue(self, gizmoName, paramName):
        value = self.sendGet('/params/%s.%s' % (gizmoName, paramName), 'value')

        didConvert = [True]
        retval = self.parseJsonFloat(value, didConvert)
        
        if not didConvert[0]:
            retval = self.parseJsonString(value)

        return retval

    def getParameterValues(self, gizmoName, paramName, count = -1, offset = 0):
        '''
        if count == -1:
            count = getParameterSize(gizmoName, paramName)
        '''

        if count == -1:
            try:
                count = self.getParameterSize(gizmoName, paramName)
            except:
                count = 1

        values = self.sendGet('/params/%s.%s' % (gizmoName, paramName),
                              'values',
                              json.dumps({'count' : count, 'offset' : offset}))

        # HACK to pass variable by reference
        didConvert = [True]
        retval = self.parseJsonFloatList(values, didConvert)
        
        if not didConvert[0]:
            retval = self.parseJsonStringList(values)
            
        return retval[:min(count, len(retval))]

    def setParameterValue(self, gizmoName, paramName, value):
        self.sendPut('/params/%s.%s' % (gizmoName, paramName), json.dumps({'value' : value}))

    def setParameterValues(self, gizmoName, paramName, values, offset = 0):
        self.sendPut('/params/%s.%s' % (gizmoName, paramName), json.dumps({'offset' : offset, 'values' : values}))

    def appendExperimentMemo(self, experiment, memo):
        self.sendPut('/experiment/notes', json.dumps({'experiment' : experiment, 'memo' : memo}))

    def appendSubjectMemo(self, subject, memo):
        self.sendPut('/subject/notes', json.dumps({'subject' : subject, 'memo' : memo}))

    def appendUserMemo(self, user, memo):
        self.sendPut('/user/notes', json.dumps({'user' : user, 'memo' : memo}))

    def startDemo(self, name):
        if name not in self.demoExperiments:
            raise Exception('%s is not a valid demo experiment' % name)
        if self.getCurrentExperiment() != name:
            if name not in self.getKnownExperiments():
                raise Exception('Experiment %s not found' % name)
            if self.getModeStr() != 'Idle':
               self.setModeStr('Idle')
            try:
                self.setCurrentExperiment(name)
            except:
                raise Exception('Experiment %s not selected' % name)

        if self.demoRequiredGizmos[name] not in self.getGizmoNames():
            raise Exception('Required gizmo %s not found' % self.demoRequiredGizmos[name])

        if self.getModeStr() == 'Idle':
            self.setPersistMode('Fresh')
            self.setModeStr('Record')
