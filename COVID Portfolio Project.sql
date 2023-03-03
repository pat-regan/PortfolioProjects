SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

SELECT * 
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Select data we're going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs. Total Deaths 
-- Shows liklihood of dying if you contract COVID in the U.S.
Create View UsCovidCasesVsDeaths as
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs. Population
-- Shows percentage of population that has gotten COVID in U.S.

Select Location, date, population, total_cases,(total_cases/population)*100 AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
ORDER BY 1,2

-- Countries with highest infection rate compared to population
Create View PercentPopInfectedPerCountry as
Select Location, MAX(total_cases) AS TopInfectionCount, (MAX(total_cases/population))*100 AS PercentPopInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopInfected DESC

-- Showing countries with highest death count per population
Create View DeathCountByCountry as
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Death count broken down by continent
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent is NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

DELETE FROM PortfolioProject..CovidDeaths 
WHERE Location = 'High Income'

DELETE FROM PortfolioProject..CovidDeaths 
WHERE Location = 'Upper Middle Income', 'Lower middle income', 'Low income'

DELETE FROM PortfolioProject..CovidDeaths 
WHERE Location = 'Lower middle income'

DELETE FROM PortfolioProject..CovidDeaths 
WHERE Location = 'Low income'

--BROKEN OUT BY CONTINENTS WITH HIGHEST DEATH COUNT
Create View DeathCountByContinent as
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent is not NULL 
GROUP BY continent
--ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
Create View GlobalDeathPercentage as
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--Group by date
ORDER BY 1,2

-- Looking at total population vs. vaccinations 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by 
 dea.location, dea.date) as RollingPplVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null	
ORDER BY 2,3

--Using CTE 

WITH PopvsVac(Continen, location, Date, Population, New_Vaccinations, RollingPplVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by 
 dea.location, dea.date) as RollingPplVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null	
)
Select*, (RollingPplVaccinated/Population)*100
From PopvsVac

--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPplVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
Select *, (RollingPplVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating view to store data for later visualizations 

DROP View if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPplVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
