#!/usr/bin/env ruby
require 'csv'
require 'date'
require 'json'

EQUIPO = {
    dalvarez: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    adebrouvier: {working_hours: 8, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    mincem: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    sblanco: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    fcassanello: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    gnativo: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    gciavirella: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0},
    gbordanzi: {working_hours: 6, done: 0, estimated:0, ongoing: 0, ongoing_estimate: 0}
}

fileName = ARGV[0]
abort 'File name required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless fileName

teamFile = ARGV[1]
abort 'Teams file name required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless teamFile

month = ARGV[2]
abort 'Corresponding Month number required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless month
month = month.to_i
abort 'Month Number must be between 1 - 12' unless 1 <= month && month <= 12 

year = ARGV[3]
abort "Year Required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020" unless year

def hours_by_person(table, month, year)
    table.each do |row|
        next unless row['Responsable']
        next unless date_in_interval(row['Actualizada'], month, year)

        unless EQUIPO[row['Responsable'].to_sym]
            EQUIPO[row['Responsable'].to_sym] = {
                    done: 0,
                    estimated: 0,
                    ongoing: 0,
                    ongoing_estimate: 0
            }
        end

        if row['Estado'].upcase == 'EN CURSO'
                EQUIPO[row['Responsable'].to_sym][:ongoing] += to_hours(row['Tiempo Trabajado'].to_i)
                EQUIPO[row['Responsable'].to_sym][:ongoing_estimate] += to_hours(row['Estimación original'].to_i)
        elsif row['Estado'].upcase == 'FINALIZADA' 
                EQUIPO[row['Responsable'].to_sym][:done] += to_hours(row['Tiempo Trabajado'].to_i)
                EQUIPO[row['Responsable'].to_sym][:estimated] += to_hours(row['Estimación original'].to_i)            
        end    
    end
end

def to_hours(seconds)
    (seconds/3600.0).round(2)
end

def date_from(year, month)
    DateTime.new(year.to_i, month.to_i).to_date
end

def date_to(year, month)
    DateTime.new(year.to_i, month.to_i, -1).to_date
end

def date_in_interval(date_str, month, year)
    date = Date.parse(translate_date_str(date_str))
    date_from(year, month) <= date && date <= date_to(year,month)
end

def translate_date_str(date)
    date
        .gsub(/ene/, 'jan')
        .gsub(/abr/, 'apr')
        .gsub(/ago/, 'aug')
        .gsub(/dic/, 'dec')
end

def get_team_headers
    EQUIPO.keys.map do |key|
        EQUIPO[key].keys.map do |subkey|
            "#{key}_#{subkey}"
        end    
    end.flatten    
end

def get_team_values
    EQUIPO.keys.map do |key|
        EQUIPO[key].values
    end.flatten
end


table = CSV.parse(File.read(fileName), headers: true)


date = Time.now.utc
hours_by_person(table, month, year)


TEAM_HEADERS = ['Date', 'Month'] + get_team_headers

TEAM_VALUES = [date, month] + get_team_values

teamNewFile = File.size?(teamFile)
open(teamFile, 'a') do |f|
    f.puts(TEAM_HEADERS.join(',') + "\n") if teamNewFile.nil?
    f.puts(TEAM_VALUES.join(',') + "\n")
end