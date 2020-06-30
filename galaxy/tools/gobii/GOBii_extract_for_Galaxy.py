#!/usr/bin/env python
# title           :GOBii_extract_for_Galaxy.py
# description     :This will help the user to pull the data from GOBii using BrAPI calls.
# author          :s.sivasubramani@cgiar.org
# date            :20190729
# version         :0.1
# usage           :python GOBii_extract_for_Galaxy.py
# notes           :
# python_version  :3.7.4
# ==============================================================================

import requests
import sys
import os
from optparse import OptionParser

# page size for variantset/[variantsetdbid]/calls
PAGESIZE = 100000
# set it True to enable the validation. This will slow down the Variantset module, because there will be BrAPI call
# for each variantsetdbid to test if the data exists
ENABLE_VALIDATION = False

usage = "usage: python %prog [options] \n\n\t\
%prog -m Authenticate -U http://hackathon.gobii.org:8081/gobii-dev/ -u username -p password \n\t\
%prog -m Variantset -U http://hackathon.gobii.org:8081/gobii-dev/ -x KYxmnDfwwgcIM+17tvavIlU -o outputFile\n\t\
%prog -m Extract -U http://hackathon.gobii.org:8081/gobii-dev/ -x KYxmnDfwwgcIM+17tvavIlU -v 4 -o outputFile\n\t\
"
parser = OptionParser(usage=usage)
parser.add_option("-m", "--module", dest="module",
                  help="One of the modules to perform. \"Authenticate\", \"Variantset\", \"Extract\"",
                  metavar="Authenticate")
parser.add_option("-U", "--url", dest="url", help="GDM url. eg: http://hackathon.gobii.org:8081/gobii-dev/",
                  metavar="URL")
parser.add_option("-u", "--username", dest="username", help="GDM username. eg: gadm", metavar="USERNAME")
parser.add_option("-p", "--password", dest="password", help="GDM password. eg: g0b11Admin", metavar="PASSWORD")
parser.add_option("-x", "--authToken", dest="authToken",
                  help="GDM Authentication Token for the API communitation. eg: "
                       "KYxmnDfwwgcIM+17tvavIlUScsxB3dVjUp/itwqWR5A=",
                  metavar="token")
parser.add_option("-v", "--variantsetID", dest="variantSetId", help="variantsetID to pul data from GDM.", metavar="4")
parser.add_option("-o", "--outFile", dest="outFile", help="Output file name.", metavar="FILE")
parser.add_option("-q", "--quiet", action="store_false", dest="verbose", default=True,
                  help="don't print status messages to stdout")

(options, args) = parser.parse_args()
"""
function to extract the Access Token from GOBii GDM using Auth call
IMPORTANT: Make sure the api_path call it uses from gobii auth as BrAPI does not have auth calls
    url: GDM instance url (eg: http://hackathon.gobii.org:8081/gobii-dev/)
    username: GDM unstance username
    password: Password for the use 'username'
    return: access token pulled using the API
"""


def get_token(url, username, password):
    """
    Function to get access token using "GOBii API" call
    :param url: GOBii GDM url
    :param username: GDM username
    :param password: GDM password
    :return: accessToken
    """
    api_path = "gobii/v1/auth"
    headers = {"X-Username": username, "X-Password": password}
    r = requests.post(url + api_path, headers=headers)
    return (r.json()["token"])


def get_variantset_table(url, accessToken, outFile):
    """
    funtion to extract dictionary of information available under the GDM instance
    :param url: GDM url eg: http://hackathon.gobii.org:8081/gobii-dev/
    :param accessToken: accessToken String got from getAccessToken
    :param outFile: OuputFile to create table of results
    :return:
    """
    api_path = "brapi/v1/variantsets"
    headers = {"X-Auth-Token": accessToken}
    r = requests.get(url + api_path, headers=headers)
    return jsonToFile(r.json(), outFile, accessToken)


def writeMatrixToFile(genotypeMatrix, outFile):
    """
    Funtion to write dictionary to a file
    :param genotypeMatrix: dictionary of genotype call dict[markerName][genotypeName]
    :param outFile: output file name
    :return:
    """
    outHeader = "marker_name"
    outFileHandle = open(outFile, 'w')
    for sampleName in genotypeMatrix["name"]:
        outHeader = outHeader + "\t" + sampleName
    outFileHandle.write(outHeader + "\n")

    for markerName in genotypeMatrix:
        if markerName is not "name":
            outString = markerName
            for sampleName in genotypeMatrix[markerName]:
                outString = outString + "\t" + genotypeMatrix[markerName][sampleName]
            outFileHandle.write(outString + "\n")
    return outFileHandle.close()


def get_variant_calls(url, accessToken, variantSetId, pageToken):
    """
    Function to use BrAPI variantset/[variantsetid]/call
    :param url: GDM url
    :param accessToken:
    :param variantSetId: variantsetdbid
    :param pageToken:
    :return:
    """
    api_path = "brapi/v1/variantsets/" + str(variantSetId) + "/calls"
    headers = {"X-Auth-Token": accessToken}
    if not pageToken:
        params = {"pageSize": PAGESIZE}
    else:
        params = {"pageSize": PAGESIZE, "pageToken": pageToken}
    r = requests.get(url + api_path, params=params, headers=headers)
    return r


def get_variantset_matrix(url, accessToken, variantSetId, outFile):
    """
    function to pull genotype matix and parse that to a tab
    :param url:
    :param accessToken:
    :param variantSetId:
    :param outFile:
    :return:
    """
    genotypeMatrix = {}
    pageToken = ''
    r = get_variant_calls(url, accessToken, variantSetId, pageToken)
    if "error" in r.json():
        sys.stderr.write("Dataset not found for the search critieria")
        return False
    else:
        if "nextPageToken" in r.json()["metaData"]["pagination"]:
            pageToken = r.json()["metaData"]["pagination"]["nextPageToken"]
        genotypeMatrix = jsonToDictionary(r.json(), genotypeMatrix)
        while pageToken:
            r = get_variant_calls(url, accessToken, variantSetId, pageToken)
            if "nextPageToken" in r.json()["metaData"]["pagination"]:
                pageToken = r.json()["metaData"]["pagination"]["nextPageToken"]
            else:
                pageToken = ""
            genotypeMatrix = jsonToDictionary(r.json(), genotypeMatrix)
        return writeMatrixToFile(genotypeMatrix, outFile)


def jsonToFile(jsonOut, outFile, accessToken):
    """
    For the Variantset module, API return the json object and this method prints the JSON as a table to the output file
    :param jsonOut: variantset BrAPI get request json object
    :param outFile: output file name to write the table to
    :return: closed the output file handle
    """
    outFileHandle = open(outFile, 'w')
    header = "variantSetId" + "\t" + "variantSetName" + "\t" + "studyDbId" + "\t" + "studyName" + "\n"
    outFileHandle.write(header)
    for variantSet in jsonOut["result"]["data"]:
        variantSetId = variantSet["variantSetDbId"]
        studyDbId = variantSet["studyDbId"]
        variantSetName = variantSet["variantSetName"]
        studyName = variantSet["studyName"]
        if ENABLE_VALIDATION:
            r = get_variant_calls(url, accessToken, variantSetId, pageToken='')
            if "error" not in r.json():
                outString = str(variantSetId) + "\t" + variantSetName + "\t" + str(studyDbId) + "\t" + studyName + "\n"
                outFileHandle.write(outString)
        else:
            outString = str(variantSetId) + "\t" + variantSetName + "\t" + str(studyDbId) + "\t" + studyName + "\n"
            outFileHandle.write(outString)
    return outFileHandle.close()


def jsonToDictionary(jsonOut, genotypeMatrix):
    """
    converts variantset/calls BrAPI output json to a dictionary of marker and samples
    :param jsonOut:
    :param genotypeMatrix:
    :return:
    """
    if "name" not in genotypeMatrix:
        genotypeMatrix["name"] = {}
    for variantSet in jsonOut["result"]["data"]:
        callSetName = variantSet["callSetName"]
        variantName = variantSet["variantName"]
        genotype = variantSet["genotype"]["string_value"]
        if callSetName not in genotypeMatrix["name"]:
            genotypeMatrix["name"][callSetName] = callSetName
        if variantName not in genotypeMatrix:
            genotypeMatrix[variantName] = {}
        genotypeMatrix[variantName][callSetName] = genotype
    return genotypeMatrix


"""
__MAIN__
"""
if options.module == "Authenticate":
    # if os.path.isfile(options.outFile):
    #     os.remove(options.outFile)
    required = "url username password".split()
    for req in required:
        if options.__dict__[req] is None:
            parser.error("parameter %s required" % req)
    url = options.url
    username = options.username
    password = options.password
    outFile = options.outFile
    accessToken = get_token(url, username, password)
    print(accessToken)

elif options.module == "Variantset":
    if os.path.isfile(options.outFile):
        os.remove(options.outFile)
    required = "url authToken outFile".split()
    for req in required:
        if options.__dict__[req] is None:
            parser.error("parameter %s required" % req)
    url = options.url
    authToken = options.authToken
    outFile = options.outFile
    get_variantset_table(url, authToken, outFile)

elif options.module == "Extract":
    if os.path.isfile(options.outFile):
        os.remove(options.outFile)
    required = "url authToken variantSetId outFile".split()
    for req in required:
        if options.__dict__[req] is None:
            parser.error("parameter %s required" % req)
    url = options.url
    authToken = options.authToken
    variantSetId = options.variantSetId
    outFile = options.outFile
    if os.path.isfile(options.outFile):
        os.remove(outFile)
    get_variantset_matrix(url, authToken, variantSetId, outFile)

elif options.module:
    if os.path.isfile(options.outFile):
        os.remove(options.outFile)
    sys.stderr.write("Module specified does not exist.\n\n")
    parser.print_help()
    sys.exit(1)

else:
    if os.path.isfile(options.outFile):
        os.remove(options.outFile)
    sys.stderr.write("Please specify the module.\n\n")
    parser.print_help()
    sys.exit(1)
