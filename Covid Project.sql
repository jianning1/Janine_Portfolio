SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE continent IS NOT NULL
--WHERE date = '2022-02-01'
WHERE location = 'Africa'
ORDER BY 2, 3, 4;

--SELECT *
--FROM ProjectPortfolio.dbo.CovidVaccinations
--ORDER BY 3, 4;




SELECT location, date, total_cases, new_cases, total_deaths, population
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location like '%Canada%'
AND continent IS NOT NULL
ORDER BY 1, 2;

--  Total cases vs Population
--  Shows what percentage of population got Covid
SELECT location, date, population, total_cases,  ROUND((total_cases/population)*100, 2) AS InfectionRate
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location = 'Canada'
AND continent IS NOT NULL
ORDER BY 1, 2;


-- Looking at Countries with Highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  ROUND(MAX(total_cases/population)*100, 2) AS InfectionRate
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC;

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;




--- By contienent
-- Showing continent with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Global Numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, ROUND((SUM(CAST(new_deaths AS int))/SUM(new_cases))*100, 2) AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;


-- Cumulative total_cases
SELECT date, SUM(total_cases) AS total_cases, SUM(CAST(total_deaths AS int)) AS total_deaths, ROUND((SUM(CAST(total_deaths AS int))/SUM(total_cases))*100, 2) AS DeathPercentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;



SELECT *,
	   SUM(total_cases) OVER (ORDER BY date) AS cumu_total_cases
FROM
	(SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, ROUND((SUM(CAST(new_deaths AS int))/SUM(new_cases))*100, 2) AS DeathPercentage		
	FROM ProjectPortfolio.dbo.CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY date) TMP
ORDER BY 1, 2;




SELECT *
FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE continent IS NOT NULL
--WHERE date = '2022-02-01'
WHERE location = 'Africa'
ORDER BY 2, 3, 4;


-- Looking at Total Population vs Vaccinations

SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations, 
		SUM(CAST(V.new_vaccinations AS int)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinated,
FROM ProjectPortfolio.dbo.CovidDeaths D JOIN ProjectPortfolio.dbo.CovidVaccinations V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
ORDER BY 2, 3;




-- Use CTE

With PopvsVac (continent, location, date, population, ew_vaccinations, RollingPeopleVaccinated)
AS
(SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations, 
		SUM(CAST(V.new_vaccinations AS int)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio.dbo.CovidDeaths D JOIN ProjectPortfolio.dbo.CovidVaccinations V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- TEMP TABLE
DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations, 
		SUM(CAST(V.new_vaccinations AS bigint)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio.dbo.CovidDeaths D JOIN ProjectPortfolio.dbo.CovidVaccinations V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated;


-- Lastest Death Percentage
SELECT * FROM
	(SELECT location, date, total_cases, population, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage,
		   RANK() OVER (PARTITION BY location ORDER BY date DESC) AS rnk
	FROM ProjectPortfolio.dbo.CovidDeaths) T
WHERE rnk = 1 AND continent IS NOT NULL
ORDER BY 5;

-- Creating view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations, 
		SUM(CAST(V.new_vaccinations AS bigint)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS RollingPeopleVaccinated
FROM ProjectPortfolio.dbo.CovidDeaths D JOIN ProjectPortfolio.dbo.CovidVaccinations V
ON D.location = V.location
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--ORDER BY 2, 3

SELECT * FROM PercentPopulationVaccinated;