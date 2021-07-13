#!/usr/bin/python3

import os
import psycopg2
from datetime import datetime

from configparser import ConfigParser

def config(filename='database.ini', section='postgresql'):
    # create a parser
    parser = ConfigParser()
    # read config file
    parser.read(filename)
    # get section, default to postgresql
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception('Section {0} not found in the {1} file'.format(section, filename))
    return db

def drop_view(view_name):
    sql = "DROP VIEW IF EXISTS " + view_name + ";"

    conn = None

    try:
        # read database configuration
        params = config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        cur.execute(sql)
        # get the powervs_id back
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def create_view(view_name, source_table):

    sql="CREATE VIEW " + view_name + " AS (SELECT * FROM " + source_table + ");"
    conn = None

    try:
        # read database configuration
        params = config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        cur.execute(sql)
        # get the powervs_id back
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()

def create_table(table_name):

    sql="CREATE TABLE " + table_name + " AS (SELECT * FROM all_images) with no data;"
    conn = None

    try:
        # read database configuration
        params = config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        # create a new cursor
        cur = conn.cursor()
        # execute the INSERT statement
        cur.execute(sql)
        # get the powervs_id back
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()


def copy_data(table,csv_file):
    conn = None
    powervs_id = None
    try:
        # read database configuration
        params = config()
        # connect to the PostgreSQL database
        conn = psycopg2.connect(**params)
        # create a new cursor
        cur = conn.cursor()
        with open(csv_file, 'r') as csv:
            cur.copy_from(csv,table,sep=',')
        conn.commit()
        # close communication with the database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()
    return powervs_id


if __name__ == '__main__':

    if os.path.exists("all.csv"):
        today = datetime.today().strftime('%Y%m%d_%H%M%S')
        new_table = "all_images_" + today
        create_table(new_table)
        copy_data(new_table,"all.csv")
        drop_view("pvsdata_all_images")
        create_view("pvsdata_all_images",new_table)
    else:
        print ("ERROR: could not locate the required .csv file")
        exit(1)
