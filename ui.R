
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)

shinyUI(fluidPage(

  # Application title
  titlePanel("Annual Bigfoot Sightings"),

  # Sidebar with a slider input for number of bins
  fluidRow(
    column(12,
      sliderInput("yr",
                  "Year of Sighting:",
                  min = 1960,
                  max = 2016,
                  value = 1960,
                  sep="",
                  animate=TRUE)
    )
  ),
  fluidRow(
    column(12,
           plotOutput("distPlot")
    )
  ),
  
  fluidRow(
    column(12,
           plotOutput("seriesPlot")
    )
  )
  
  # Show a plot of the generated distribution
))
