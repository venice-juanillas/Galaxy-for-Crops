#
#   Author:		Ángela Pacheco & Juan Burgueño
#   Institution:	CIMMYT - Biometrics adn Statistics Unit
#   Date:		10-May-2019
#
#

library(shiny)
library(DT)
library(ggplot2)


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Genetic Gain Calculator"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            helpText("The GG calculator uses the breeder's equation to model the impact of selection intensity, heritability, genetic variance, and cycle length on the rate of genetic gain expected from one cycle of selection.  The model allows you to explore the impact of different allocations of testing resources, and permits sensitivity analysis with respect to differing relative variance component magnitudes for those variances contributing to the variance of the mean of a selection unit.  The GG calculator models gains per cycle and per year assuming that parents of the next cycle are selected from a single year of Stage 1 testing.  "),
            hr(),
            textInput('VG', 'Genetic Variance', "0.21,0.24"),
	    helpText("*Genetic variance must be > 0"),
            textInput("VGL", "GenotypexLocation Variance", "0.01,0.02"),
            textInput("VGY", "GenotypexYear Variance", "0.06,0.07"),
            textInput("VGLY", "GenotypexLocationxYear Variance", "0.3,0.4"),
            textInput("VE", "Residual Variance", "0.57,0.58"),
            textInput("nL", "Number of Locations", "3,2"),
            textInput("nR", "Number of replicates", "1,2"),
            textInput("nC", "Number of selection candidates", "50,50"),
            textInput("nP", "Number of lines selected as parents of the next cycle", "10,10"),
	    helpText("*Number of lines selected as parents of the next cycle  must be less than Number of selection candidates"),
            textInput("CY", "Years per cycle", "6,6")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            
            fluidRow(
                column(width = 6,
                       plotOutput("plot1", height = 300)
                ),
                column(width = 6,
                       plotOutput("plot2", height = 300)
                )
            ),
           #plotOutput("distPlot"),
           #verbatimTextOutput("oid2")
           DT::dataTableOutput("mytable")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    doData<-reactive({
	# add validation
	validate(
		need(input$VG != "", label= "Genetic Variance"),
		need(input$VGL != "", label= "GenotypexLocation Variance"),
		need(input$VGY != "", label= "GenotypexYear Variance"),
		need(input$VGLY != "", label= "GenotypexLocationxYear Variance"),
		need(input$VE != "", label= "Residual Variance"),
		need(input$nL != "", label= "Number of Locations"),
		need(input$nR != "", label= "Number of replicates"),
		need(input$nC != "", label= "Number of selection candidates"),
		need(input$nP != "", label= "Number of lines selected as parents of the next cycle"),
		need(input$CY != "", label= "Years per cycle")
	)
        VG1 <- as.numeric(unlist(strsplit(input$VG,",")))
        VGL1 <- as.numeric(unlist(strsplit(input$VGL,",")))
        VGY1 <- as.numeric(unlist(strsplit(input$VGY,",")))
        VGLY1 <- as.numeric(unlist(strsplit(input$VGLY,",")))
        VE1 <- as.numeric(unlist(strsplit(input$VE,",")))
        nL1 <- as.numeric(unlist(strsplit(input$nL,",")))
        nR1 <- as.numeric(unlist(strsplit(input$nR,",")))
        nC1 <- as.numeric(unlist(strsplit(input$nC,",")))
        nP1 <- as.numeric(unlist(strsplit(input$nP,",")))
        CY1 <- as.numeric(unlist(strsplit(input$CY,",")))
        propsel<-round(nP1/nC1,3)
   	h2<-round(VG1/( VG1+(VGL1/nL1)+VGY1+(VGLY1/nL1)+(VE1/(nL1*nR1)) ),3)
        acc<-round(h2^0.5,3)
        th<-round(-qnorm(propsel),3)
        hth<-round(exp(-0.5*(th^2))/sqrt(2*pi),3)
        ssdinf<-round(hth/propsel,3)
        ssdfin<-round(ssdinf-(nC1-(nC1*propsel))/(2*propsel*nC1*((nC1+1)*ssdinf)),3)
        GC<-round(ssdfin*acc*sqrt(VG1),3)
        GY<-round(GC/CY1,3)
        dataout<-as.data.frame(cbind(VG1,VGL1,VGY1,VGLY1,VE1,nL1,nR1,nC1,nP1,
                                     propsel,CY1,h2,GC,GY))
        names(dataout)=c("Genetic variance", "GxL Variance","GxY Variance", "GxLxY Variance",
                         "Residual variance", "Number of locations", "Number of replicates", 
                         "Number of selection candidates", "Number of selected lines as parents of the next cycle",
                         "Proportions selected","Year per cycle" ,"Heritability", "Gain per cycle","Gain per year")
        dataout
    })  
    
    output$plot1 <- renderPlot({
        y    <- doData()$"Gain per cycle"
        x <-1:length(y)
        dataplot<-as.data.frame(cbind(x,y))
        ggplot(dataplot, aes(x=as.factor(x), y=y, fill=as.factor(x))) +
            geom_bar(stat="identity", position="stack") + labs(x="",y="Gain per cycle") + 
            theme(legend.position="none",
                  text = element_text(size=20, face="bold"),
                  axis.title.y = element_text(size=16, face="bold")
                  )
    })
    
    output$plot2 <- renderPlot({
        y    <- doData()$"Gain per year"
        x <-1:length(y)
        dataplot<-as.data.frame(cbind(x,y))
        ggplot(dataplot, aes(x=as.factor(x), y=y, fill=as.factor(x))) +
            geom_bar(stat="identity", position="stack") + labs(x="",y="Gain per year") + 
            theme(legend.position="none",
                  text = element_text(size=20, face="bold"),
                  axis.title.y = element_text(size=16, face="bold")
                  )
    })
    
    output$mytable = DT::renderDataTable({
        dataout<-as.data.frame(doData())
        datatable(dataout, selection="multiple", escape=FALSE, 
                  options = list(sDom  = '<"top">lrt<"bottom">ip'))
    })
    
}


# Run the application 

shinyApp(ui = ui, server = server, options=list(port = 5907))
