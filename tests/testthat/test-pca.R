
test_that("diagram_kpca detects incorrect parameters correctly",{
  
  D <- data.frame(dimension = c(0),birth = c(0),death = c(1))
  expect_error(diagram_kpca(diagrams = list(D,D,D[,1:2]),num_workers = 2),"three")
  expect_error(diagram_kpca(diagrams = list(D,D,D),t = -1,num_workers = 2),"t")
  expect_error(diagram_kpca(diagrams = list(D,D,D),sigma = 0,num_workers = 2),"sigma")
  expect_error(diagram_kpca(diagrams = list(D,D,D),dim = NULL,num_workers = 2),"dim")
  
})

test_that("diagram_kpca is computing correctly",{
  
  D1 <- data.frame(dimension = 0,birth = 2,death = 3)
  D2 <- data.frame(dimension = 0,birth = 2,death = 3.1)
  D3 <- data.frame(dimension = 0,birth = c(2,5),death = c(3.1,6))
  k12 <- diagram_kernel(D1,D2)
  k13 <- diagram_kernel(D1,D3)
  k23 <- diagram_kernel(D2,D3)
  K <- matrix(data = c(1,k12,k13,k12,1,k23,k13,k23,1),nrow = 3,ncol = 3,byrow = T)
  K <- scale(K,center = T,scale = F)
  K <- t(scale(t(K),center = T,scale = F))
  eig <- eigen(K)
  kpca <- diagram_kpca(diagrams = list(D1,D2,D3),features = 2,num_workers = 2)
  expect_equal(as.numeric(kpca$pca@pcv[,1]),(kpca$pca@pcv[1,1]/eig$vectors[1,1])*as.numeric(eig$vectors[,1]))
  expect_equal(as.numeric(kpca$pca@pcv[,2]),(kpca$pca@pcv[1,2]/eig$vectors[1,2])*as.numeric(eig$vectors[,2]))
  expect_equal(as.numeric(kpca$pca@eig)/sum(as.numeric(kpca$pca@eig)),eig$values[1:2]/sum(eig$values[1:2]))
  
})

test_that("predict_diagram_kpca detects incorrect parameters correctly",{
  
  D1 <- data.frame(dimension = 0,birth = 2,death = 3)
  D2 <- data.frame(dimension = 0,birth = 2,death = 3.1)
  D3 <- data.frame(dimension = 0,birth = c(2,5),death = c(3.1,6))
  kpca <- diagram_kpca(diagrams = list(D1,D2,D3),features = 2,num_workers = 2)
  expect_error(predict_diagram_kpca(new_diagrams = list(),kpca,num_workers = 2),"1")
  expect_error(predict_diagram_kpca(new_diagrams = NA,kpca,num_workers = 2),"NA")
  expect_error(predict_diagram_kpca(new_diagrams = list(diagrams[[1]],1),kpca,num_workers = 2),"diagram")
  expect_error(predict_diagram_kpca(new_diagrams = list(D1,D2,D3),embedding = 2,num_workers = 2),"kpca")
  
})

test_that("predict_diagram_kpca is computing correctly",{
  
  D1 <- data.frame(dimension = 0,birth = 2,death = 3)
  D2 <- data.frame(dimension = 0,birth = 2,death = 3.1)
  D3 <- data.frame(dimension = 0,birth = c(2,5),death = c(3.1,6))
  kpca <- diagram_kpca(diagrams = list(D1,D2,D3),features = 2,num_workers = 2)
  expect_equal(predict_diagram_kpca(new_diagrams = list(D1,D2,D3),embedding = kpca,num_workers = 2),kpca$pca@rotated)
  
})

