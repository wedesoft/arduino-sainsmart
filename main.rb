#!/usr/bin/env ruby
require 'Qt4'
require_relative 'sainsmartwidget'
require_relative 'client'

DEVICE = '/dev/ttyUSB0'
BAUD = 115200
app = Qt::Application.new ARGV
client = Client.new DEVICE, BAUD
window = SainsmartWidget.new client
window.show
app.exec
