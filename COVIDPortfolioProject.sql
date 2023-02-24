SELECT TOP 1000 *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT TOP 1000 *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Total Cases vs Total Deaths in the USA
-- Shows probability of contracting COVID-19
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows us what percentage of the population has contracted COVID-19
SELECT Location, date, population, total_cases, (total_cases / population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population))*100 as 
PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Shows Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as bigint)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Sort By Continent (correct numbers)

SELECT location, MAX(cast(total_deaths as bigint)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Sort By Continent(wrong numbers, but looks better)

SELECT continent, MAX(cast(total_deaths as bigint)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers by date
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, 
	SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Global Numbers Total
SELECT SUM(new_cases) as total_cases, 
       SUM(CONVERT(bigint, new_deaths)) as total_deaths, 
       (SUM(CONVERT(bigint, new_deaths)) * 100.0 / NULLIF(SUM(new_cases),0)) AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Joins both tables and looks at Total Population vs Vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND dea.location = 'United States' 
ORDER BY 2,3

-- Joins both tables and looks at Total Population vs Vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, TotalVaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (TotalVaccinations / population)*100 as PercentageVaccinated
FROM PopVsVac


-- Use Temp Table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_Vaccinations numeric,
TotalVaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date

SELECT *, (TotalVaccinations/Population)*100
FROM #PercentPopulationVaccinated


-- Create View to store for visualizations

Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as TotalVaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT * 
FROM PercentPopulationVaccinated


-- Joins both tables and looks at Total Population vs Vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND dea.location = 'United States' 
ORDER BY 2,3


-- Fix date time on CovidDeaths table

SELECT DeaDateConverted, CONVERT(Date, date) 
FROM PortfolioProject..CovidDeaths
ORDER BY DeaDateConverted

ALTER TABLE CovidDeaths
Add DeaDateConverted Date;

UPDATE CovidDeaths
SET DeaDateConverted = CONVERT(Date, date)

-- Fix date time on CovidVaccinations table

SELECT VacDateConverted, CONVERT(Date, date)
FROM PortfolioProject..CovidVaccinations
ORDER BY VacDateConverted

ALTER TABLE CovidVaccinations
Add VacDateConverted Date;

UPDATE CovidVaccinations
SET VacDateConverted = CONVERT(Date, date)


-- Shows death percentage of people vaccinated | Not finished

SELECT dea.continent, dea.location, dea.DeaDateConverted, dea.total_deaths, vac.people_fully_vaccinated,
SUM(CAST(vac.people_fully_vaccinated as decimal)/ dea.total_deaths)*100 as FullyVaccinatedDeathPercentage
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccinations as vac
	ON dea.location = vac.location
	and dea.DeaDateConverted = vac.VacDateConverted
WHERE dea.continent is not null
AND vac.people_fully_vaccinated is not null
AND dea.location = 'United States' 
GROUP BY dea.continent, dea.location, dea.DeaDateConverted, dea.total_deaths, vac.people_fully_vaccinated
ORDER BY dea.location, dea.DeaDateConverted;