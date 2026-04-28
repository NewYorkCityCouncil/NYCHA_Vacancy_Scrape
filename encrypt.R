# encrypt.r

# Add the path to Node.js & npm if using nvm (adjust if needed)
# to find where yours is use "which npm" in terminal
Sys.setenv(PATH = paste(Sys.getenv("PATH"), "/Users/rhirota/.nvm/versions/node/v22.16.0/bin", sep = ":"))

# Load the staticryptR package
library(staticryptR)

# Run the encryption
staticryptr(
  files = "docs",        # Folder where Quarto puts the site
  directory = ".",       # Output directory (where to save encrypted content)
  password = "#####",
  short = TRUE,
  recursive = TRUE,
  template_color_primary = "#035c84",
  template_color_secondary = "#f9f9f3",
  template_title = "Public Restrooms",
  template_instructions = "Enter password or contact the Data Team for access.",
  template_button = "Submit"
)