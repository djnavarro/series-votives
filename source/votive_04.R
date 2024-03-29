seed <- 10

votive01 <- function(seed) {
  
  library(Rcpp)
  library(ggplot2)
  library(ggforce)
  library(voronoise)
  library(dplyr)
  
  sys_id <- "04"
  sys_name <- "votive"
  sourceCpp(here::here("source", paste0(sys_name, "_", sys_id, ".cpp")))
  
  # seed
  cat(seed, "\n")
  set.seed(seed)
  
  # fixed / default
  scheme <- seed
  layers <- sample(10:20, 1)
  iter <- 100000
  low <-  .006
  high <- .0125
  f <- 1
  col_trans <- rank
  ex <- 0
  rd <- 0
  zoom <- .6
  
  # filename
  prefix <- paste0(sys_name, "_", sys_id, "_")
  fname <- paste0(prefix, seed, ".png")
  fpath <- here::here("image", fname)
  
  
  
  
  # palette specification ---------------------------------------------------
  
  pal <- sample(colours(distinct = TRUE), 3)
  pal <- (colorRampPalette(pal))(layers)
  bg <- sample(c("grey10", "ghostwhite"), 1)
  
  if(seed == 1) pal <- scico::scico(1000)
  if(seed == 2) pal <- scico::scico(1000, direction = -1, palette = "lajolla")
  if(seed == 3) pal <- scico::scico(1000, palette = "batlow")
  if(seed == 4) pal <- paletteer::paletteer_c("ggthemes::Orange-Blue Diverging", 1000, -1)
  if(seed == 5) pal <- paletteer::paletteer_c("ggthemes::Orange-Blue Diverging", 1000)
  if(seed == 6) pal <- rainbow(1000, s = .6)
  if(seed == 7) pal <- gameofthrones::got(1000, option = "targaryen")
  if(seed == 8) pal <- gameofthrones::got(1000, option = "baratheon")
  if(seed == 9) pal <- scico::scico(1000, palette = "broc")
  
  if(seed == 10) {
    pal <- scico::scico(1000, palette = "turku")
    layers <- 100
    zoom <- .4
  }
  
  # generate the data -------------------------------------------------------
  
  cat("generating...\n")
  
  # create data frame
  df <- votive_data(iter, layers)
  df <- as.data.frame(df)
  names(df) <- c("x","y","c")
  
  # filter and transform
  df <- df[-(1:100),]
  filter_x <- c(-f, f)
  filter_y <- c(-f, f)
  if(!is.null(filter_x)) {
    x_ok <- df$x > filter_x[1] & df$x < filter_x[2]
    y_ok <- df$y > filter_y[1] & df$y < filter_y[2] 
    df <- df[x_ok & y_ok, ]
  }
  if(!is.null(col_trans)){
    df$c <- col_trans(df$c)
  }

  # scale the co-ordinates to the image size
  px <- 5000
  xrng <- max(df[,1]) - min(df[,1])
  yrng <- max(df[,2]) - min(df[,2])
  rng <- max(c(xrng, yrng))
  
  # create a vector of colours
  ncol <- length(pal)
  cc <- 4
  col_idx <- as.integer((df[,cc] - min(df[,cc])) / (max(df[,cc]) - min(df[,cc])) * (ncol - 1)) + 1L
  df$col <- pal[col_idx]
  
  
  
  
  # generate the image ------------------------------------------------------
  
  cat("rendering...\n")
  
  sift <- function(low = .005, high = .025) {
    function(data) {
      data <- data %>% 
        group_by(group) %>%
        mutate(tilesize = (max(x) - min(x)) * (max(y) - min(y))) %>%
        ungroup()
      data$tilealpha <- 1
      bright <- data$tilesize < high^2 & data$tilesize > low^2
      data$tilealpha[bright] <- 1
      data$tilerank <- rank(-data$tilesize)
      ind <- (data$tilerank - min(data$tilerank))/(max(data$tilerank) - min(data$tilerank))
      ind <- as.integer(ind * (ncol - 1)) + 1
      data$tileshade <- pal[ind]
      return(data)
    }
  }
  
  p <- ggplot(
    data = df,
    mapping = aes(
      x = x, 
      y = y, 
      group = 1, 
      fill = after_stat(tileshade), 
      alpha = after_stat(tilealpha)
    )
  ) + 
    geom_voronoise(
      perturb = sift(low, high), 
      max.radius = NULL, 
      radius = rd, 
      expand = ex
    ) +
    scale_fill_identity() + 
    scale_alpha_identity() + 
    scale_x_continuous(expand = c(0, 0)) +
    scale_y_continuous(expand = c(0, 0)) +
    theme_void() + 
    theme(panel.background = element_rect(fill = bg, colour = bg)) + 
    coord_cartesian(
      xlim = filter_x * zoom, 
      ylim = filter_y * zoom
    )
  
  ggsave(
    file = fpath,
    plot = p,
    width = 5000 / 300,
    height = 5000 / 300,
    dpi = 300
  )
  
}

for(s in seed) votive01(s)
