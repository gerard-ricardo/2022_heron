# Fst (between pops) and FIS (Inbreeding Coefficient) ---------------------------------------------------------------------

## ITHINK USE COLONY OUTPUTS AS THEY ACCOUNT FOR GENTYPING ERROR APPROPORATLY
##Note that many inbreeding calcs here might be biased because of null alleles and geotyping errors increase homozygotes. 
#have added null alleles filter to genind , need to check
## avoid using genlight because I cant filter null IDs

# Extract unique and then cluster (not subset only seems to work on genlight file)
# ind_names <- indNames(data_gl_filtered_adult)
# genotypes <- data_gl_filtered_adult@other$ind.metrics$genotype
# geno_df <- data.frame(individual = ind_names, genotype = genotypes, stringsAsFactors = FALSE)
# (unique_geno_df <- geno_df %>% distinct(genotype, .keep_all = TRUE))
# unique_indices <- match(unique_ind_names, indNames(data_gl_filtered_adult))
# data_gl_filtered_unique <- data_gl_filtered_adult[unique_indices, ]


#subset group 1
# cluster_1_indices <- which(data_genind_adult_unique@other$ind.metrics$cluster == 1)
# data_gl_filtered_cluster1 <- data_gl_filtered_adult[cluster_1_indices, ]
# data_gl_filtered_cluster1@other$ind.metrics$cluster <- droplevels(data_gl_filtered_cluster1@other$ind.metrics$cluster)
# data_genind_cluster1 <- gl2gi(data_gl_filtered_cluster1)




#basic relatedness stats
# bs.nc <- basic.stats(data_genind_adult)
# bs.nc

#null ID filtering on, n = 2 reps
#Ho (0-1)      Hs(0-1)      Ht      Dst (0-1)     Htp     Dstp     Fst (0-1)    Fstp     Fis (-1 to 1)    Dest 
#0.0765       0.0517        0.1655  0.1138        0.1726  0.1209    0.6876      0.7004  -0.4804           0.1275 

#unique and grouped and filter for null IDs
pop_info <- data_genind_adult_unique@other$ind.metrics$cluster # population information for individuals
genotypes <- tab(data_genind_adult_unique)  # genotype matrix (one locus per column)
bs_df <- data.frame(Population = pop_info, genotypes)
(bs.nc <- basic.stats(bs_df))
# Ho      Hs      Ht     Dst     Htp    Dstp     Fst    Fstp     Fis    Dest 
# 0.6019  0.3515  0.3680  0.0165  0.3768  0.0253  0.0448  0.0672 -0.7125  0.0390


#null ID filtering off
bs.nc <- basic.stats(data_genind_adult_subset1)
bs.nc


gl.report.heterozygosity(data_gl_filtered_adult)


# Weir and Cockerham estimates
wc(data_genind_adult[, -2])  #Computes Weir and Cockerham estimates of Fstatistics
#agrees with above
# The high FST suggests a high level of differentiation among populations, while the negative FIS suggests a
# possible excess of heterozygotes (outcrossing) within the populations.

## Fst  - genetic differentiation among subpopulations.
# Calculate population-specific Fst values for the filtered genetic data
betas(data_genind_adult)
# Extract the population-specific Fst values
betas_values <- betas(data_genind_adult)$betaiovl
sorted_betas <- sort(betas_values)
sorted_betas
barplot(sorted_betas,
        main = "Population-specific Fst Values",
        ylab = "Fst", xlab = "Population", col = "steelblue",
        las = 2
)

# Overall Inbreeding Coefficient.0 means random mating.  Positive values indicate a deficiency of heterozygotes,
# suggesting inbreeding. Negative values indicate an excess of heterozygotes, suggesting outcrossing.
# Pos values might be related to clones and self fert (but probably not)

(bs.nc <- basic.stats(data_genind_adult_subset1))
gl.report.heterozygosity(data_genind_adult_subset1)
# Ho      Hs      Ht     Dst     Htp    Dstp     Fst    Fstp     Fis    Dest 
# 0.0873  0.0569  0.1224  0.0655  0.1337  0.0768  0.5348  0.5742 -0.5336  0.0814 

(bs.nc <- basic.stats(data_genind_adult_cluster2))
# Ho      Hs      Ht     Dst     Htp    Dstp     Fst    Fstp     Fis    Dest 
# 0.0697  0.0487  0.1164  0.0677  0.1247  0.0761  0.5819  0.6097 -0.4322  0.0800
(bs.nc <- basic.stats(data_genind_adult_subset3))
# Ho      Hs      Ht     Dst     Htp    Dstp     Fst    Fstp     Fis    Dest 
# 0.0657  0.0448  0.0448  0.0000     NaN     NaN  0.0000     NaN -0.4674     NaN

# inbreeding coefs --------------------------------------------------------


# Calculate inbreeding coefficients
data_genind_adult_unique@pop <- data_genind_adult_unique@other$ind.metrics$cluster
values <- inbreeding(data_genind_adult_unique)
(median__values <- lapply(values, median))
(df <- do.call(rbind, median__values)) 

values_all <- inbreeding(data_genind)
(median__values_all <- lapply(values_all, median))

values_1 <- inbreeding(data_genind_adult_subset1)
(median_values_1 <- lapply(values_1, median))
(df1 <- do.call(rbind, median_values_1))  #

values_2 <- inbreeding(data_genind_adult_subset2)
(median_values_2 <- lapply(values_2, median))
(df2 <- do.call(rbind, median_values_2))  #

ids <- rep(names(values), times = sapply(values, length))  # Repeat each name according to the length of each list element
values_flat <- unlist(values, use.names = FALSE)  # Unlist without preserving names to avoid auto-generated names
df <- data.frame(id = ids, bbb = values_flat)
df$id <- as.factor(as.character(df$id))
# Define a function to calculate mode
calculate_mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# Compute mode for each id and create a data frame of modes
mode_df <- df %>% group_by(id) %>% summarise(mode = calculate_mode()) %>% data.frame()
str(df)
levels(df$id)

#median
(med_df <- df %>% dplyr::group_by(id) %>% dplyr::summarise(med = median(bbb, na.rm = TRUE)) %>% data.frame())
median(med_df$med)
plot(density(med_df$med), xlab  = 'Inbreeding coef')

# Join the mode back to the original dataframe
str(df)
str(mode_df)
df <- left_join(df, med_df, by = "id") %>%  arrange(med)  # Joining the mode values back to the original dataframe based on id
range(df$bbb)
#remotes::install_github("R-CoderDotCom/ridgeline@main")
library(ridgeline)
ridgeline(df$bbb, df$id, mode = T) 

# Sort the Fst values from low to high
sorted_ <- arrange(med_df, med)
sorted_

# Extract the mode values from the sorted data frame
height <- sorted_$med

# Create the bar plot with sorted  values
barplot(height,names.arg = sorted_$id, main = "Individual-specific  Values", ylab = "",  col = "blue", las = 2)


# excess homos in selfed larvae -------------------------------------------

(stats_adult <- basic.stats(data_genind_parents))
stats_adult$Fis
(indiv_mean_adult <- colMeans(stats_adult$Fis, na.rm = TRUE))
mean(indiv_mean_adult, na.rm = TRUE)
(stats_progeny <- basic.stats(data_genind_progeny))
stats_progeny$Fis
(indiv_mean_prog <- colMeans(stats_progeny$Fis, na.rm = TRUE))
mean(indiv_mean_prog, na.rm = TRUE)
#data_genind_adult@pop

# Shapiro-Wilk test for normality on both groups
shapiro.test(indiv_mean_adult)  # For adults
shapiro.test(indiv_mean_prog)   # For progeny.
#wilcox.test(indiv_mean_adult, indiv_mean_prog)  #no need for wilcox as they are normal after null allele filtering
# Combine the two groups into a single vector
combined_data <- c(indiv_mean_adult, indiv_mean_prog)
#check homogensity
group_factor <- factor(c(rep("Adults", length(indiv_mean_adult)), 
                         rep("Progeny", length(indiv_mean_prog))))
car::leveneTest(combined_data, group_factor)
t.test(indiv_mean_adult, indiv_mean_prog, var.equal = TRUE)
#t = -6.3858, df = 6, p-value = 0.0006938


#########(Identify disequilibrium (ranges 0 - 1)
library(inbreedR)
data('mouse_snps')
mat_0_1_coded
str(mat_0_1_coded)
check_data(mat_0_1_coded, num_ind = 35, 1454)
g2 = g2_snps(mat_0_1_coded, nperm = 100, nboot =100, CI = 0.95)
plot(g2)
r2_hf(mat_0_1_coded, nboot = 100, type = 'msats')
r2_Wf(mat_0_1_coded, nboot = 100, type = 'msats')


# Hardy-Weinberg equilibrium and heterozygote excess----------------------------------------------
##NOTE: Ho and He might be affect by high null alleles. Might be best to use values created from Cervus as this adjust for nul alleles. 

# Perform HWE test for each locus
hwe_results <- hw.test(data_genind_adult, B = 0)  # B is the number of permutations
#Significant deviations can indicate factors such as inbreeding, genetic drift, selection, or self-fertilisation.

##Identify loci with heterozygote excess:
# Extract p-values and heterozygote excess information
hwe_pvalues <- hwe_results[, 3]
# Adjust p-values for multiple testing using Bonferroni correction
p_adjusted <- p.adjust(hwe_pvalues, method = "fdr")
# Identify loci with significant heterozygote excess after adjustment
significant_loci <- which(p_adjusted < 0.05)
# Extract observed and expected heterozygosity for these loci
obs_het <- summary(data_genind_adult)$Hobs
exp_het <- summary(data_genind_adult)$Hexp
# Check for heterozygote excess
heterozygote_excess <- obs_het > exp_het
# Loci with significant heterozygote excess
loci_het_excess <- which(heterozygote_excess & (p_adjusted < 0.05))
# Print loci with heterozygote excess
loci_het_excess
length(loci_het_excess)

# Check for heterozygote deficit
heterozygote_deficit <- obs_het < exp_het
# Loci with significant heterozygote deficit
loci_het_deficit <- which(heterozygote_deficit & (p_adjusted < 0.05))
# Print loci with heterozygote deficit
print(loci_het_deficit)
# Number of loci with heterozygote deficit
num_loci_het_deficit <- length(loci_het_deficit)
print(num_loci_het_deficit)

# Plot observed vs expected heterozygosity
# plot(obs_het ~exp_het, xlab = "Expected Heterozygosity", ylab = " Observed Heterozygosity")
# abline(0, 1, col = "red")
# points(obs_het[loci_het_excess]~ exp_het[loci_het_excess], col = "blue", pch = 19)
# Points below the red line indicate loci with a deficiency of heterozygotes (observed < expected), suggesting 
#inbreeding or other factors.Points above the red line indicate loci with an excess of heterozygotes (observed > 
#expected), which can suggest outcrossing, heterozygote advantage, or self-fertilisation.

# Create a data frame from the observed and expected heterozygosity
data_plot <- data.frame(Expected = exp_het, Observed = obs_het, Color = "black")
data_plot$Color[loci_het_excess] <- "steelblue2"
data_plot$Color[loci_het_deficit] <- "orchid4"

# Create the plot
ggplot(data_plot, aes(x = Expected, y = Observed, color = Color)) +
  geom_point(alpha = 0.6, size = 2) +
  scale_color_identity() +  # Use actual colors stored in 'Color' column
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  labs(
    title = "Observed vs Expected Heterozygosity",
    x = "Expected Heterozygosity",
    y = "Observed Heterozygosity"
  ) +
  theme_sleek2() +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "none"
  )
ggsave( filename = 'heron_pHo_vs_He.tiff',  path = "./plots", device = "tiff",  width = 5, height = 5)  #this often works better than pdf

# G diversity (not working) -------------------------------------------------------------

Go <- apply(tab(data_genind_adult_unique), 1, function(x) length(unique(x))) # Number of unique genotypes per locus
Ge <- apply(tab(data_genind_adult_unique), 1, function(locus) {
  p <- sum(locus * (1:length(locus)-1)) / sum(locus) # Calculate allele frequency p for bi-allelic loci
  1 - (p^2 + (1-p)^2) # HW expected heterozygosity for a bi-allelic locus
})


# A primer of conservation genetics equations pg 186 (working but issues)----------------------

#the F and S are implausible. Possible genotyping errors 

# Assuming 'data_genind' is your genind object containing all individuals
ind_names <- indNames(data_genind)
# Find the index of the maternal plant 'pd15.a.1'
mum_index <- which(ind_names == 'pd15.a.1')
# Extract the maternal plant
maternal_plant <- data_genind[mum_index, ]

# Extract progeny of 'pd15.a.1'
# Assuming progeny are named in a pattern like 'pd15.a.1.<suffix>'
progeny_indices <- grep('^pd15.l\\.', ind_names, value = FALSE) # Use correct pattern to match progeny names
# Exclude the maternal plant from progeny
progeny_indices <- progeny_indices[progeny_indices != mum_index]
# Extract the progeny
progeny_genind <- data_genind[progeny_indices, ]

# Calculate observed heterozygosity (Ho) for progeny
summary_progeny <- summary(progeny_genind)
Ho <- summary_progeny$Hobs

# Calculate expected heterozygosity (He) for progeny
He <- summary_progeny$Hexp

# Calculate average observed and expected heterozygosity
Ho_avg <- mean(Ho, na.rm = TRUE) # Average observed heterozygosity
He_avg <- mean(He, na.rm = TRUE) # Average expected heterozygosity

# Check if Ho_avg and He_avg are correctly calculated
cat("Average observed heterozygosity (Ho):", Ho_avg, "\n")
cat("Average expected heterozygosity (He):", He_avg, "\n")

# Compute the inbreeding coefficient (F)
F <- 1 - (Ho_avg / He_avg)

# Determine the selfing rate (S)
S <- (2 * F) / (1 + F)

# Print results
cat("Inbreeding coefficient (F):", F, "\n")
cat("Selfing rate (S):", S, "\n")



# cervus analysis ---------------------------------------------------------

#Run output  cervus script first and ensure the most up to data pd_afa_out2.txt file in 1b_2022heron_seq_process_other.R
#These values are senstive to null allelel filtering

(Ho_avg = mean(data1$HObs, na.rm = T)) 
hist(data1$HObs)
(Ho_med = median(data1$HObs, na.rm = T)) 

(He_avg = mean(data1$HExp, na.rm = T))
hist(data1$HExp)
(He_med = median(data1$HExp, na.rm = T))

## this indicates hetero excess, but might also be from filtering null allees


# Calculate F_IS (inbreeding coefficient) for each locus
data1$F_IS <- (data1$HExp - data1$HObs) / data1$HExp
hist(data1$F_IS)
# Calculate the mean F_IS
med_F_IS <- median(data1$F_IS, na.rm = TRUE)
# Display the mean F_IS
med_F_IS




# Determine the selfing rate (S) - only work with positive F (i.e evidence of  inbreeding)
(S1 <- (2 * F1) / (1 + F1))

