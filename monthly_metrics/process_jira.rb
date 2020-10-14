#!/usr/bin/env ruby
require 'csv'
require 'date'
require 'json'


fileName = ARGV[0]
abort 'File name required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless fileName

outputFileName = ARGV[1]
abort 'Output file name required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless outputFileName

featureName = ARGV[2]
abort 'Feature name required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless featureName

month = ARGV[3]
abort 'Corresponding Month number required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020' unless month
month = month.to_i
abort 'Month Number must be between 1 - 12' unless 1 <= month && month <= 12 

year = ARGV[4]
abort "Year Required, Ej: ./process_jira.rb Septiembre/customer_visual.csv teams.csv conglomerated.csv customer_visual 8 2020" unless year




def estimated_time(table)
    to_hours(table.by_col[3].compact.map(&:to_i).inject(:+))
end

def remaining_time(table)
    result = 0
    table.each do |row|
        result += row['Estimación original'].to_i unless is_finished?(row)
    end
    to_hours(result)
end

def spent_time(table)
    to_hours(table.by_col[4].compact.map(&:to_i).inject(:+))
end    

def ongoing_time(table)
    result = 0
    table.each do |row|
        result += row['Tiempo Trabajado'].to_i if is_ongoing?(row)
    end
    to_hours(result)    
end 

def hours_on_estimated_tasks(table)
    result = 0
    table.each do |row|
        result += row['Tiempo Trabajado'].to_i unless row['Estimación original'].nil? || row['Estimación original'].empty?
    end
    to_hours(result)
end

def hours_on_unestimated_tasks(table)
    result = 0
    table.each do |row|
        result += row['Tiempo Trabajado'].to_i if row['Estimación original'].nil? || row['Estimación original'].empty?
    end
    to_hours(result)
end


# Relacion existente entre tareas sin estimar (BUGS) y tareas estimadas (issues)
# Podemos usarlo para predecir ante un numero X de estimacion, cuanto tiempo nos llevaria ya que sabriamos que 
# generalmente manejamos un coeficiente Y de bugfixing, entonces si tenemos 10 horas estimaadas y nuestro coeficiente
# es 0.5, sabemos que nos va a llevar 15 horas (10 + 10*0.5) contando el bugfixing
def bugfix_coeficient(unestimated, estimated)
    unestimated / estimated
end

def is_ongoing?(row)
    return false unless row['Estado']
    row['Estado'].upcase == 'EN CURSO'
end   

def is_finished?(row)
    return false unless row['Resolución']
    row['Resolución'].upcase == 'LISTO'
end

def to_hours(seconds)
    (seconds/3600.0).round(2)
end

# La relacion entre las horas dedicadas a tareas estimadas contra las horas estimadas en si.
# Esto significa que si es positivo, tengo mas horas invertidas de las que la estimacion decia que tenia que invertir 
# (Es decir fui menos eficiente de lo que pense) -> subestime tareas
# Si el resultado es negativo, significa que tengo menos horas invertidas en tareas que la estimacion de las mismas
# (Es decir fui mas eficiente de lo que pense) -> sobreestime tareas
# Al eliminar el calculo si hay tareas en curso, eliminamos las medias estimaciones. 
# Esta metrica es mas que nada para features cerrados para ver solo sobre las tareas estimadas, cuanto subestimamos.

def subestimated_coeficient(estimated, remaining, hours_on_estimated, ongoing)
    return 0 if ongoing > 0
    (hours_on_estimated - (estimated - remaining))/(estimated - remaining)
end 


table = CSV.parse(File.read(fileName), headers: true)

estimatedTime = estimated_time(table)
spentTime = spent_time(table)
remainingTime = remaining_time(table)
ongoingTime = ongoing_time(table)
hoursOnEstimated = hours_on_estimated_tasks(table)
hoursOnUnestimated = hours_on_unestimated_tasks(table)
bugfix = bugfix_coeficient(hoursOnUnestimated, hoursOnEstimated)
subestimated = subestimated_coeficient(estimatedTime, remainingTime, hoursOnEstimated, ongoingTime)
date = Time.now.utc

COLUMNS= %w[
    Date 
    Month 
    Feature 
    EstimatedTime 
    RemainingTime 
    UsedTime 
    OngoingTime 
    HoursOnEstimatedTasks 
    HoursOnUnestimatedTasks 
    BugfixCoef
    Subestimated
]
DATA = [
    date,
    month,
    featureName, 
    estimatedTime,
    remainingTime,
    spentTime,
    ongoingTime,
    hoursOnEstimated,
    hoursOnUnestimated,
    bugfix,
    subestimated
]

newFile = File.size?(outputFileName)
open(outputFileName, 'a') do |f|
    f.puts(COLUMNS.join(',') + "\n") if newFile.nil?
    f.puts(DATA.join(',') + "\n")
end



